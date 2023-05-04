include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:2])
#D = D[4]


nullPos = 1000

startPos = 0
endPos  = 28000

speedSetup=2000



for i in 1:2
    speedReset = getSpeed(D[i+2])
    setSpeed(D[i+2], speedSetup)
end

command_move(D[3], nullPos, nullPos)
command_move(D[4], nullPos, nullPos)


for i in 1:2
    nowPos_BIG_CH =  getPos(D[3])
    nowPos_BIGGER_CH = getPos(D[4])
    pos_data = Vector{Position}(undef, 0)
    f_data = getFreqAsBinBlockTransfer(vna)
    current = 1
    posSet = getMeasurementPositions(startPos, endPos; stepSize=500)

    if i % 2 == 0
        commandMove(D[4],  nullPos, 0)
        commandWaitForStop(D[4])
    
        commandMove(D[3], 1000*i, 0)
        commandWaitForStop(D[3])
        println(i,"ungerade")
    else
        commandMove(D[4], endPos, 0)
        commandWaitForStop(D[4])

        while true
            currentPos = getPos(D[4])
        
            # Check wether the current position has passed the intended point of measurement.
            # The condition if a point has been passed is dependent on the direction of travel.
            if endPos > startPos
                passed = isGreaterEqPosition(currentPos, Position(posSet[current], 0))
            else
                passed = isGreaterEqPosition(Position(posSet[current], 0), currentPos)
            end
        
            # If a point has been passed, perform a measurement
            if passed
                storeTraceInMemory(vna, current)
                push!(pos_data, currentPos)
                current += 1
                if currentPos == length(posSet) + 1 break end
            end
        
            # Redundant check if the end has been reached, in case a measurement position lies
            # beyond the end position
            if currentPos.Position == endPos break end
        end
        
        commandMove(D[3],  1000*i, 0)
        commandWaitForStop(D[3])
        println(i,"gerade")
    end
end

closeDevices(D[1:4])
    







