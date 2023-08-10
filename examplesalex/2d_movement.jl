include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:2])

#Basic VNA settings
power=-20
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweepPoints::Integer = 128
ifbandwidth::Integer = 100e3


#Resolution of the scan, a number between 1 and 7 needs to be selected. The bigger the number the lower the resolution 
res = 6
name::String = "TESTTESTTEST"

#Connect to the VNA and start basics setup
vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)





@time S, f, pos_BIGGER, pos_BIG, posSet = twoDMeasurement(vna, 4000, 18000; speed=2000, speedSetup=2000, res=res, sweepPoints=sweepPoints)

meas = Measurement2D("", vnaParam, f, S, pos_BIGGER, pos_BIG, posSet)
saveMeasurement(meas; name=name)

closeDevices(D)

data = readMeasurement("TESTTESTTEST_2023-07-31_1.jld2")
transData = transform(data, sweepPoints, res)

plotPoints(data, sweepPoints, res, transData)
plotGaussianFit2D(data, sweepPoints, res, transData)


#Wenn man sich eine bestimmte Frequenz anschauen will
# freqIndex = argmin(abs.(data.freq .- 20*10^9))
# plotHeatmap2D(data, freqIndex)

anim = @animate for freqIndex in 1:sweepPoints	
    plotHeatmap2D(data, freqIndex)
end
gif(anim, "anim_"*name*".gif", fps = 10)





#movetonull(0,2000)

#plotFreq(meas,4)

for i in 1:45
    deleteTrace(vna, i)
end
commandMove(D[4], 4000, 0)
commandMove(D[3], 4000, 0)

