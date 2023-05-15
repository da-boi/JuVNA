include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
#checkOrdering(D,stagenames)
#closeDevices(D[1:2])
#D = D[4]


#Mittlere Position der Line beim Spiegel ist bei ca. 14247 steps, 164 usteps

power=-20
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweeppoints::Integer = 128
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"
vNum = 5


vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweeppoints, ifbandwidth=ifbandwidth)

@time S, f, pos, posSet = twoDMeasurement(vna, 0, 5000; speed=2000, speedSetup=2000, stepSize=500, vNum=vNum, sweepPoints=sweeppoints)
meas = Measurement("", vnaParam, f, S, pos, posSet)
saveMeasurement(meas; filename="2D-firstTests")

for i in 1:vNum
    deleteTrace(vna, i)
end
closeDevices(D)
    









