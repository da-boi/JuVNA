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
f_span::Float64 = 3e9
sweeppoints::Integer = 128
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz], power=power, center=f_center, span=f_span, sweepPoints=sweeppoints, ifbandwidth=ifbandwidth)

@time S, f, pos, posSet = performContinousMeasurement(vna, 0, 28000; speed=1000, speedSetup=1000, stepSize=500)
meas = Measurement("speedtest", vnaParam, f, S, pos, posSet)
saveMeasurement(meas; filename="metalwire_3GHz.data")

plotHeatmap(meas)
plotGaussianFit(meas)

meas_floss = readMeasurement("floss_3GHz.data")
meas_metal = readMeasurement("metalwire_3GHz.data")

plotGaussianFit([meas_floss, meas_metal])