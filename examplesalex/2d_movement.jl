include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:2])

#D = D[4]


#Mittlere Position der Line beim Spiegel ist bei ca. 14247 steps, 164 usteps
power=-20
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweepPoints::Integer = 128
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"

vNum = 1
name::String = "2D_CristalRB3-07_test"

motorSet = 1            #1 Dominik ist nicht da  2 Dominik ist da

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)


#movetonull(0,2000)

@time S, f, pos_BIGGER, pos_BIG, posSet = twoDMeasurement(vna, 0, 20000; speed=2000, speedSetup=2000, stepSize=500, vNum=vNum, sweepPoints=sweepPoints, motorSet=motorSet)

meas = Measurement2D("", vnaParam, f, S, pos_BIGGER, pos_BIG, posSet)
saveMeasurement(meas; name=name)


data = readMeasurement("2D_CristalRB3-07_test_2023-06-05_1.jld2")
transData = transform(data)


#Wenn man sich eine bestimmte Frequenz anschauen will
#freqIndex = argmin(abs.(data.freq .- 20*10^9))
#plotHeatmap2D(data, freqIndex)

anim = @animate for freqIndex in 1:sweepPoints	
    plotHeatmap2D(data, freqIndex)
    println(freqIndex)
    
end

gif(anim, "anim_"*name*".gif", fps = 10)

plotPoints(data)





#movetonull(0,2000)
#commandMove(D[4], 0, 0)

#plotFreq(meas,4)
#=
for i in 1:50
    deleteTrace(vna, i)
end
=#
closeDevices(D)


#Plotten klappt so halb, wahrscheinlich wird jede Zweite Zeile flasch herum geplottet!


