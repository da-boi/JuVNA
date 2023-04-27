include("../src/JuXIMC.jl")

function getMeasurementPositions(startPos::Integer, endPos::Integer; stepSize::Integer=250)
    if startPos <= endPos
        return [x for x in startPos:stepSize:endPos]
    else
        return reverse([x for x in endPos:stepSize:startPos])
    end
end

function getContinousMeasurement(startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000)
    f_data = getFreqAsBinBlockTransfer(vna)
    S_data = Vector{Vector{Float64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)

    measPos = getMeasurementPositions(startPos, endPos; stepSize=stepSize)
    currentMeasPosIndex = 1

    setSpeed(D, 1000)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)
    setSpeed(D, speed)
    commandMove(D, endPos, 0)

    while true
        currentPos = getPos(D)
        if isGreaterEqPosition(currentPos, Position(measPos[currentMeasPosIndex], 0))
            push!(S_data, getDataAsBinBlockTransfer(vna))
            push!(pos_data, currentPos)
            println(currentPos)
            currentMeasPosIndex += 1
            if currentMeasPosIndex == length(measPos) + 1 break end
        end
    end
end

function getSteppedMeasurement(startPos::Integer, endPos::Integer; stepSize::Integer=250)
    f_data = getFreqAsBinBlockTransfer(vna)
    S_data = Vector{Vector{Float64}}(undef, 0)
    pos_data = Vector{Position}(undef, 0)

    measPos = getMeasurementPositions(startPos, endPos; stepSize=stepSize)

    setSpeed(D, 1000)
    commandMove(D, startPos, 0)
    commandWaitForStop(D)

    for x in measPos
        commandMove(D, x, 0)
        commandWaitForStop(D)
        currentPos = getPos(D)
        push!(S_data, getDataAsBinBlockTransfer(vna))
        println(currentPos)
    end
end