import Dates
import Serialization
using JLD2, FileIO

include("../src/JuXIMC.jl")
include("../src/vna_control.jl")

struct Measurement
    label::String
    param::VNAParameters
    freq::Vector{Float64}
    data::Matrix{ComplexF64}
    pos::Vector{Position}
    posSet::Vector{Integer}
end
function saveMeasurement(data; filename::String="", name::String="unnamed", filedate=true)
    if filename == ""
        if filedate date = Dates.format(Dates.now(), "yyyy-mm-dd_") else date = "" end
        i = 1
        while true
            filename = name * "_" * date * string(i) * ".jld2"
            if !isfile(filename) break end
            i += 1
        end
    end

    @save filename data

    return
end

function readMeasurement(filename::String)
    @load filename data

    return data
end

function getMeasurementPositions(startPos::Integer, endPos::Integer; stepSize::Integer=500)
    if startPos <= endPos
        return Vector{Integer}(startPos:stepSize:endPos)
    else
        return reverse(Vector{Integer}(endPos:stepSize:startPos))
    end
end

function getContinousMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000, speedSetup::Integer=1000)
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(socket)

    # Calculate all the points at which a measurement is to be done
    posSet = getMeasurementPositions(startPos, endPos; stepSize=stepSize)
    current = 1

    # Move to starting Position
    # speedSetup can be higher than the measuring speed
    speedReset = getSpeed(D)
    setSpeed(D, speedSetup)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)

    # Start the measuring movement
    setSpeed(D, speed)
    commandMove(D, endPos, 0)

    while true
        currentPos = getPos(D)

        # Check wether the current position has passed the intended point of measurement.
        # The condition if a point has been passed is dependent on the direction of travel.
        if endPos > startPos
            passed = isGreaterEqPosition(currentPos, Position(posSet[current], 0))
        else
            passed = isGreaterEqPosition(Position(posSet[current], 0), currentPos)
        end

        # If a point has been passed, perform a measurement
        if passed
            storeTraceInMemory(socket, current)
            push!(pos_data, currentPos)
            current += 1
            if currentPos == length(posSet) + 1 break end
        end

        # Redundant check if the end has been reached, in case a measurement position lies
        # beyond the end position
        if currentPos.Position == endPos break end
    end

    # Read the data from Memory

    # Reset the speed to the prior speed
    setSpeed(D, speedReset[begin])

    S_data = Vector{Vector{ComplexF64}}(undef, 0)

    complexFromTrace(data::Vector{Float64}) = data[1:2:end] .+ data[2:2:end]*im

    if (current-1) < length(posSet)
        error("Measurement points missing: motor speed probably to high")
    end

    for i in 1:(length(posSet))
        push!(S_data, complexFromTrace(getTraceFromMemory(socket, i)))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
end

function getSteppedMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000)
    S_data = Vector{Vector{ComplexF64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(socket)

    # Calculate all the points at which a measurement is to be done
    posSet = getMeasurementPositions(startPos, endPos; stepSize=stepSize)

    # Move to starting Position
    setSpeed(D, 1000)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)

    # Perform a measurement for each intended point
    for x in posSet
        commandMove(D, x, 0)
        commandWaitForStop(D)
        push!(S_data, getDataAsBinBlockTransfer(socket))
        push!(pos_data, Position(x, 0))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
end



function twoDMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000, speedSetup::Integer=1000,vNum::Integer=5, sweepPoints::Integer)
    speedReset = getSpeed(D[4])
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(vna)
    current = 1
    posSet = getMeasurementPositions(startPos, endPos; stepSize=500)
           
    for i in 1:2
        
        setSpeed(D[i+2], speedSetup)  
        commandMove(D[i+2], startPos, 0) 
        commandWaitForStop(D[i+2])
        
    end
    S_data = Matrix{Vector{ComplexF64}}(undef, sweepPoints, vNum)
    for i in 1:vNum
        println("Runde ", i)
        if i == 1    
            commandMove(D[4], endPos, 0)
            commandWaitForStop(D[4])
            println("Erster Move")    

        elseif i % 2 == 0
            commandMove(D[3], stepSize*i, 0)
            commandWaitForStop(D[3])
            
            commandMove(D[4],  startPos, 0)
            commandWaitForStop(D[4])
            println(i," gerade")

        else
            commandMove(D[3], stepSize*i, 0)
            commandWaitForStop(D[3])

            commandMove(D[4], endPos, 0)
            commandWaitForStop(D[4])
            println(i," ungerade")
        end
    


        while true
            currentPos = getPos(D[4])
    
            # Check wether the current position has passed the intended point of measurement.
            # The condition if a point has been passed is dependent on the direction of travel.
            if i % 2 == 0 
                passed = isGreaterEqPosition(Position(posSet[current], 0), currentPos)
                println(passed)
                println("KLAPPT RÜCKWEG")
            else
                passed = isGreaterEqPosition(currentPos, Position(posSet[current], 0))
                println(passed)
                println("KLAPPT HINWEG ")
            end
        
            # If a point has been passed, perform a measurement
            if passed
                println("passed ", current)
                storeTraceInMemory(socket, current)
                push!(pos_data, currentPos)
                current += 1
                if currentPos == length(posSet) + 1 break end
            end
    
            # Redundant check if the end has been reached, in case a measurement position lies
            # beyond the end position
            if currentPos.Position == endPos || currentPos.Position == startPos break end
        end
    

#BIS HIER KLAPPTS SCHONMAL



        # Read the data from Memory

        # Reset the speed to the prior speed
        setSpeed(D[4], speedReset[begin])

        S_data_list = Vector{Vector{ComplexF64}}(undef, 0)
        
        complexFromTrace(data::Vector{Float64}) = data[1:2:end] .+ data[2:2:end]*im
        
        
        #=
        if i % 2 == 0
            if (current-1) > length(posSet)
                error("Measurement points missing: motor speed probably to high")
            end
        elseif (current-1) < length(posSet)
            error("Measurement points missing: motor speed probably to high***2")
        end
        
        for j in 1:(length(posSet))
            println(complexFromTrace(getTraceFromMemory(socket, j)))
            push!(S_data, complexFromTrace(getTraceFromMemory(socket, j)))

        end
        =#
        
        for i in 1:(length(posSet))
            push!(S_data_list, complexFromTrace(getTraceFromMemory(socket, i)))
        end
        
        println(S_data_list)
        S_data[:,1] =  S_data_list
        

        # Reform the data to a Matrix{Float64}
        #S_data = Matrix(reduce(hcat, S_data))
    
    end
    #return (S_data, f_data, pos_data, posSet)

end
    
    
    







#=
function getContinousMeasurement(startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000, speedSetup::Integer=1000)
    S_data = Vector{Vector{ComplexF64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(vna)

    # Calculate all the points at which a measurement is to be done
    posSet = getMeasurementPositions(startPos, endPos; stepSize=stepSize)
    current = 1

    # Move to starting Position
    # speedSetup can be higher than the measuring speed
    setSpeed(D, speedSetup)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)

    # Start the measuring movement
    setSpeed(D, speed)
    commandMove(D, endPos, 0)

    while true
        currentPos = getPos(D)

        # Check wether the current position has passed the intended point of measurement.
        # The condition if a point has been passed is dependent on the direction of travel.
        if endPos > startPos
            passed = isGreaterEqPosition(currentPos, Position(posSet[current], 0))
        else
            passed = isGreaterEqPosition(Position(posSet[current], 0), currentPos)
        end

        # If a point has been passed, perform a measurement
        if passed
            push!(S_data, getDataAsBinBlockTransfer(vna))
            push!(pos_data, currentPos)
            println(currentPos)
            current += 1
            if currentPos == length(posSet) + 1 break end
        end

        # Redundant check if the end has been reached, in case a measurement position lies
        # beyond the end position
        if currentPos.Position == endPos break end
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
end
=#