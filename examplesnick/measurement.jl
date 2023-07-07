import Dates
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

struct Measurement2D
    label::String
    param::VNAParameters
    speed::Integer
    freq::Vector{Float64}
    data::Matrix{Vector{ComplexF64}}
    pos::Matrix{Position}
    posSet::Matrix{Integer}
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

    # delete stray traces from incomplete previous measurements
    deleteAllTraces(vna) 

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
            if current == length(posSet) + 1 break end
        end

        # Redundant check if the end has been reached, in case a measurement position lies
        # beyond the end position
        if currentPos.Position == endPos break end
    end



    # Reset the speed to the prior speed
    setSpeed(D, speedReset[begin])

    S_data = Vector{Vector{ComplexF64}}(undef, 0)

    if (current-1) < length(posSet)
        error("Measurement points missing: motor speed probably to high")
    end

    # Read the data from Memory
    for i in 1:(length(posSet))
        push!(S_data, getTraceFromMemory(socket, i))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
end

function get2DMeasurement(socket::TCPSocket, D::Vector{DeviceId}, startPos::Tuple{Integer}, endPos::Tuple{Integer}; stepSize::Integer=250, speed::Integer=1000, speedSetup::Integer=1000)
    S_data = Matrix{Vector{ComplexF64}}(undef, 0)
    pos_data = Matrix{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(socket)

    # Calculate all the points at which a measurement is to be done
    posSetX = getMeasurementPositions(startPos[1], endPos[1]; stepSize=stepSize)
    posSetY = getMeasurementPositions(startPos[2], endPos[2]; stepSize=stepSize)
    current = 1

    # Move to starting Position
    commandMove(D, startPos)
    commandWaitForStop(D)

    # Start the measuring movement
    setSpeed(D, speed)

    for y in posSetY
        
        # Move Y-axis to next position
        commandMove(D[2], y; info=true)
        commandWaitForStop(D[2])

        # start scan
        if getPos(D[1]) == startPos[1] direction = true end

        if direction
            commandMove(D[1], endPos[1], 0)
        else
            commandMove(D[1], startPos[1], 0)
        end

        posX_data = Vector{Position}(undef, 0)
        SX_data = Vector{Position}(undef, 0)

        while true
            currentPos = getPos(D[1])

            # Check wether the current position has passed the intended point of measurement.
            # The condition if a point has been passed is dependent on the direction of travel.
            if endPos > startPos
                passed = isGreaterEqPosition(currentPos, Position(posSetX[current], 0))
            else
                passed = isGreaterEqPosition(Position(posSetX[current], 0), currentPos)
            end

            # If a point has been passed, perform a measurement
            if passed
                storeTraceInMemory(socket, current)
                push!(posX_data, currentPos)
                current += 1
                if currentPos == length(posSet) + 1 break end
            end

            # Redundant check if the end has been reached, in case a measurement position lies
            # beyond the end position
            if currentPos.Position == endPos break end
        end

        # Read the data from Memory
        SX_data = Vector{Vector{ComplexF64}}(undef, 0)

        complexFromTrace(data::Vector{Float64}) = data[1:2:end] .+ data[2:2:end]*im

        for i in 1:(length(posSet))
            push!(SX_data, complexFromTrace(getTraceFromMemory(socket, i)))
        end

        if direction SX_data = reverse(SX_data) end

        S_data = vcat(S_data, SX_data)
        pos_data = vcat(pos_data, posX_data)

    end

    return (S_data, f_data, pos_data, posSet)
end

function getSteppedMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000)
    setMeasurement(vna, "CH1_S11_1")
    
    S_data = Vector{Vector{ComplexF64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(socket)

    # Calculate all the points at which a measurement is to be done
    posSet = getMeasurementPositions(startPos, endPos; stepSize=stepSize)

    # Move to starting Position
    setSpeed(D, speed)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)

    # Perform a measurement for each intended point
    for x in posSet
        commandMove(D, x, 0)
        commandWaitForStop(D)
        push!(S_data, getTrace(socket))
        push!(pos_data, Position(x, 0))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
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