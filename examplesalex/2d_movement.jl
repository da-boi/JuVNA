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
vNum = 5

motorSet = 1            #1 Dominik ist nicht da  2 Dominik ist da

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)

@time S, f, pos_BIGGER, pos_BIG, posSet = twoDMeasurement(vna, 0, 10000; speed=2000, speedSetup=2000, stepSize=500, vNum=vNum, sweepPoints=sweepPoints, motorSet=motorSet)
length(S[1,1])

transform(S)

meas = Measurement2D("", vnaParam, f, S, pos_BIGGER, pos_BIG, posSet)
saveMeasurement(meas; filename="2D-firstTests")


calcFieldProportionality2D(meas)

#=
for i in 1:10
    deleteTrace(vna, i)
end
=#
closeDevices(D)

freq = 20*10^9

S[1,1][64]
f_index_20GHz = argmin(abs.(f .- 20*10^9))
println(f_index_20GHz)
f[64]


heatmap_data = Matrix{ComplexF64}(undef, length(posSet), vNum)

for y in 1:vNum
    for x in 1:length(posSet)
        println(S[x,y][argmin(abs.(f .- freq))])

        heatmap_data[x,y] = S[x,y][argmin(abs.(f .- freq))]
    end
end

