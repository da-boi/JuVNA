include("../src/vna_control.jl")
include("../examplesdom/stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:3])
D = D[4]


### Connect to the VNA ###
power=-20
f_center::Float64 = 19e9
f_span::Float64 = 300e6
sweeppoints::Integer = 128
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c300MHz], power=power, center=f_center, span=f_span, sweeppoints=sweeppoints, ifbandwidth=ifbandwidth, measurement=measurement)

setFastMeasurementMode(vna)
S_data, f_data, pos_data, posSet_data, mpoints = performContinousMeasurement(vna, 0, 28000; speed=1000, speedSetup=2000)
meas = Measurement(vnaParam, f_data, S_data)

plotHeatmap(meas)
plotGaussianFit(meas)



function performContinousMeasurement(socket::TCPSocket, startPos::Integer, endPos::Integer; stepSize::Integer=250, speed::Integer=1000, speedSetup::Integer=1000)
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
            storeTraceInMemory(socket, current)
            current += 1
            if currentPos == length(posSet) + 1 break end
        end

        # Redundant check if the end has been reached, in case a measurement position lies
        # beyond the end position
        if currentPos.Position == endPos break end
    end

    # Read the data from Memory
    S_data = Vector{Vector{ComplexF64}}(undef, 0)

    complexFromTrace(data::Vector{Float64}) = data[1:2:end] .+ data[2:2:end]*im

    println(current)
    for i in 1:(length(posSet))
        push!(S_data, complexFromTrace(getTraceFromMemory(socket, i)))
    end

    # Reform the data to a Matrix{Float64}
    S_data = Matrix(reduce(hcat, S_data))

    return (S_data, f_data, pos_data, posSet, current)
end