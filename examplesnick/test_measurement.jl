include("../src/vna_control.jl")
include("../examplesdom/stages.jl")
include("binaryIO.jl")
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
sweeppoints::Integer = 10
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c300MHz], power=power, center=f_center, span=f_span, sweeppoints=sweeppoints, ifbandwidth=ifbandwidth, measurement=measurement)

### Measurement ###
startPos = 0
endPos = 28000

@time S_data, f_data, pos_data, posSet_data = getSteppedMeasurement(startPos, endPos; speed=1000)
@time S_data, f_data, pos_data, posSet_data = getContinousMeasurement(startPos, endPos; speed=500)

meas = Measurement(vnaParam, f_data, S_data)
saveMeasurement(meas; filename="continous_zahnseide_300MHz.data")

plotGaussianFit(meas)
plotHeatmap(meas)