include("../src/JuXIMC.jl")

function getMeasurementPositions(startPos::Integer, endPos::Integer; stepSize::Integer=500)
    if startPos <= endPos
        return Vector{Integer}(startPos:stepSize:endPos)
    else
        return reverse(Vector{Integer}(endPos:stepSize:startPos))
    end
end

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

function getSteppedMeasurement(startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000)
    S_data = Vector{Vector{ComplexF64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(vna)

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
        push!(S_data, getDataAsBinBlockTransfer(vna))
        push!(pos_data, Position(x, 0))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet)
end