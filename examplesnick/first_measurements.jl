include("../examplesdom/stages.jl")
include("measurement.jl")
include("plot.jl")

### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:2])
DX = D[4]
DY = D[3]


### Connect to the VNA ###
power=9
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweepPoints::Integer = 128
ifbandwidth::Integer = 100e3

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_9dB], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)

### Perform measurements
startPos = 0
endPos = 24000
stepSize = 250
reps = 1

D = DX
# continous measurement
speed = 2000
# for power in [-20, -15, -10, -5, 0, 5, 9]
for i in 1:3
    @time S, f, pos, posSet = getContinousMeasurement(vna, startPos, endPos; speed=speed, speedSetup=2000, stepSize=stepSize)
    # @time S, f, pos, posSet = getSteppedMeasurement(vna, startPos, endPos; stepSize=stepSize)
    meas = Measurement("", vnaParam, f, S, pos, posSet)
    saveMeasurement(meas; name="../beadpull/method/c"*string(speed)*"_black150_cc3300_"*string(power)*"dB")
    plotGaussianFit(meas)
end

D = [DX, DY]
startPos = [0, 0]
endPos = [24880, 18000]
@time S, f, pos, posSetX, posSetY = get2DMeasurement(vna, D, startPos, endPos; speed=3200, speedSetup=2000, stepSizeX=500, stepSizeY=500)

M = Measurement2D_("", vnaParam, 2000, f, S, pos, posSetX, posSetY)
saveMeasurement(M; name="../beadpull/twoD/c3200_black150_cc3300")