import Dates
import Serialization
using JLD2, FileIO
using DelimitedFiles
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

struct Measurement2D
    label::String
    param::VNAParameters
    freq::Vector{Float64}
    data::Matrix{Vector{ComplexF64}}
    pos_BIGGER::Vector{Position}
    pos_BIG::Vector{Position}
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



function twoDMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=500, speed::Integer=1000, speedSetup::Integer=1000,vNum::Integer=5, sweepPoints::Integer, motorSet::Integer)
    
    if motorSet == 1
        BigChungus = 3
        BiggerChungus = 4
    elseif motorSet == 2
        BigChungus = 1
        BiggerChungus = 2
    else
        println("Error flasche Auswahl")
        return 
    end


    #speedReset = getSpeed(D[BiggerChungus])
    pos_data_BIGGER = Vector{Position}(undef, 0)
    pos_data_BIG = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(vna)
    
    posSet = getMeasurementPositions(startPos, endPos; stepSize=500)
    posSetLen = length(posSet)::Int64
    S_data = Matrix{Vector{ComplexF64}}(undef,  vNum, length(posSet))
           
    #=
    for i in BigChungus:BiggerChungus
        
        setSpeed(D[i], speedSetup)  
        commandMove(D[i], startPos, 0) 
        commandWaitForStop(D[i])
        
    end
    =#

    
    

    for y in 1:vNum
        println("Runde ", y)
        currentPos_BIG = getPos(D[BigChungus])
        push!(pos_data_BIG, currentPos_BIG)
        #S_data_list = Vector{ComplexF64}(undef, sweepPoints)
        
        current = 1
        if y == 1    
            commandMove(D[BiggerChungus], endPos, 0)
            #commandWaitForStop(D[BiggerChungus])
            println("Erster Move")    

        elseif y % 2 == 0
            commandMove(D[BigChungus], stepSize*y, 0)
            commandWaitForStop(D[BigChungus])
            println("Geht Runter")
            
            commandMove(D[BiggerChungus],  startPos, 0)
            #commandWaitForStop(D[BiggerChungus])
            println(y," gerade")

        else
            commandMove(D[BigChungus], stepSize*y, 0)
            commandWaitForStop(D[BigChungus])
            println("Geht Runter")

            commandMove(D[BiggerChungus], endPos, 0)
            #commandWaitForStop(D[BiggerChungus])
            println(y," ungerade")
        end
    


        while true
            currentPos_BIGGER = getPos(D[BiggerChungus])
            
            
            println("current Pos ",currentPos_BIGGER)
            # Check wether the current position has passed the intended point of measurement.
            # The condition if a point has been passed is dependent on the direction of travel.

            

            if y % 2 == 0 
                println("y gerade ")
                println(current)
                
                println("Wenn ",currentPos_BIGGER, "kleiner gleich ist als ", Position(posSet[length(posSet)+1-current],0))
                passed = isSmallerEqPosition(currentPos_BIGGER, Position(posSet[length(posSet)+1-current], 0))

                println(passed)
                println("KLAPPT RÜCKWEG")
                
            else
                println("ungerade ",length(posSet))
                println(current)
                println(typeof(current))
                passed = isGreaterEqPosition(currentPos_BIGGER, Position(posSet[current], 0))
                println(passed)
                println("KLAPPT HINWEG ")
            end
        
            # If a point has been passed, perform a measurement
            if passed
                println("passed ", current)
                storeTraceInMemory(socket, current)
                push!(pos_data_BIGGER, currentPos_BIGGER)
                current += 1
                #println(pos_data)
                if current == length(posSet) +1  break end
            end
            
           
            # Redundant check if the end has been reached, in case a measurement position lies
            # beyond the end position
            #println("while klappt halb ",currentPos.Position)
            
            #if currentPos.Position == endPos || currentPos.Position == startPos break end
    
        end
        
        
        

        # Read the data from Memory

        # Reset the speed to the prior speed
        #setSpeed(D[4], speedReset[begin])

        
        
        complexFromTrace(data::Vector{Float64}) = data[1:2:end] .+ data[2:2:end]*im
        

        for x in 1:length(posSet)
            println(y,x)
            if y % 2 == 0
                S_params = complexFromTrace(getTraceFromMemory(socket, x))
                S_data[y, length(posSet) - x + 1] = S_params
                
            else
                S_params = complexFromTrace(getTraceFromMemory(socket, x))
                S_data[y,x] = S_params
            end
                
            
            #println(typeof(S_params))
            #println(typeof(S_data))
            
           
            
            
        end

        # Reform the data to a Matrix{Float64}
        # S_data = Matrix(reduce(hcat, S_data))
        
        #println(S_data)
        println(typeof(S_data))
        #deleteTrace(socket, 1)



    end

    return (S_data, f_data, pos_data_BIGGER, pos_data_BIG, posSet)
end
    
function movetonull(startPos::Integer,speedSetup::Integer)
    for i in 3:4
        setSpeed(D[i], speedSetup)  
        commandMove(D[i], startPos, 0) 
        commandWaitForStop(D[i])
        
    end
end

#Transforming the Maxtrix where each cell contains a vector to a vector containing matricies. 
function transform(data)
    #transData = [undef, vNum, length(data.posSet) for _ in 1:sweepPoints]
    transData = [Matrix{ComplexF64}(undef, (vNum, length(data.posSet))) for _ in 1:sweepPoints]
    for f in 1:sweepPoints
        for y in 1:vNum
            for x in 1:length(data.posSet)
                transData[f][y,x] = data.data[y,x][f]
            end
        end
        println(f)
    end
    return (transData)
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