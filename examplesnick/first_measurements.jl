include("../examplesdom/stages.jl")
include("measurement.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:3])
D = D[4]


### Connect to the VNA ###
power=-20
f_center::Float64 = 19e9
f_span::Float64 = 3e9
sweeppoints::Integer = 128
ifbandwidth::Integer = 100e3

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz], power=power, center=f_center, span=f_span, sweepPoints=sweeppoints, ifbandwidth=ifbandwidth)


### Perform measurements
startPos = 0
endPos = 28000
stepSize = 250
reps = 5


# continous measurement
speed = 1000
for i in 1:reps
    commandMove(D, startPos, 0)
    @time S, f, pos, posSet = getContinousMeasurement(vna, startPos, endPos; speed=speed, speedSetup=2000, stepSize=stepSize)
    meas = Measurement("", vnaParam, f, S, pos, posSet)
    saveMeasurement(meas; name="cont_black150_al3500")
end

# stepped measurement
for i in 1:reps
    commandMove(D, startPos, 0)
    @time S, f, pos, posSet = getSteppedMeasurement(vna, startPos, endPos; stepSize=stepSize)
    meas = Measurement("", vnaParam, f, S, pos, posSet)
    saveMeasurement(meas; name="step_black150_al3500")
end


plotHeatmap(meas)
plotGaussianFit(meas)