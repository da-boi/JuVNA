include("../src/vna_control.jl")
include("../examplesdom/stages.jl")
include("dataIO.jl")
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
sweeppoints::Integer = 1024
ifbandwidth::Integer = 100e3

vna = connectVNA()
instrumentSimplifiedSetup(vna; power=power, center=f_center, span=f_span, sweeppoints=sweeppoints, ifbandwidth=ifbandwidth)
getDataAsBinBlockTransfer(vna)


### Measurement ###
startPos = 5000
endPos = 28000

@time getContinousMeasurement(startPos, endPos; speed=1000)
@time getSteppedMeasurement(startPos, endPos)