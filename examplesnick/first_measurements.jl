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
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweepPoints::Integer = 128
ifbandwidth::Integer = 100e3

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweeppoints, ifbandwidth=ifbandwidth)

### Perform measurements
startPos = 0
endPos = 24000
stepSize = 250
reps = 1


# continous measurement
speed = 2000
for i in 1:reps
    @time S, f, pos, posSet = getContinousMeasurement(vna, startPos, endPos; speed=speed, speedSetup=2000, stepSize=stepSize)
    meas = Measurement("", vnaParam, f, S, pos, posSet)
    saveMeasurement(meas; name="../beadpull/c2000_black150_cc3300")
end

# stepped measurement
# for i in 1:reps
#     @time S, f, pos, posSet = getSteppedMeasurement(vna, startPos, endPos; stepSize=stepSize, speed=2000)
#     meas = Measurement("", vnaParam, f, S, pos, posSet)
#     saveMeasurement(meas; name="../beadpull/s_black150_al3180")
# end

meas = readMeasurement("../beadpull/c2000_black150_cc3300_2023-06-14_10.jld2")

plotHeatmap(meas)
plotGaussianFit(meas)


commandMove(D, 0, 0)
@time commandWaitForStop(D)