include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
#closeDevices(D[1:2])
D = D[4]


    
plot()

for i in 1:14

    global vna = connectVNA()

    #Mittlere Position der Line beim Spiegel ist bei ca. 14247 steps, 164 usteps
    power= -21+2*i
    println(power)
    f_center::Float64 = 20e9
    f_span::Float64 = 3e9
    sweepPoints::Integer = 128
    ifbandwidth::Integer = 100e3
    #measurement::String = "CH1_S11_1"
    
    name::String = "2D_CristalRB3-07_SNR_P"* string(-21+2*i)
    println(name)

    println("Klappt bis hier")
    vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)
    
    println("power umstellen klappt")



    @time S, f, pos, posSet = getContinousMeasurement(vna, 0, 18000; speed=2000, speedSetup=2000, stepSize=500)
    meas = Measurement("", vnaParam, f, S, pos, posSet)
    saveMeasurement(meas; name=name)
    
    
    #plotHeatmap(meas)
    #plotGaussianFit(meas, power)
    
  
    disconnectVNA(vna)
end



plot()
for i in 1:14
    power= -21+2*i
    data = readMeasurement("2D_CristalRB3-07_SNR_P"*string(power)*"_2023-06-06_1.jld2")
    plotGaussianFit(data, power)
end
png("powerComp3")

#Power to noise ratio

SNR_list = []
power_list = []
plot()
for i in 1:14
    power = -21+2*i
    push!(power_list, power)
    data = readMeasurement("2D_CristalRB3-07_SNR_P"*string(power)*"_2023-06-06_1.jld2")

    #p, pErr, chiq, ndof = GaussianFit(data)
    #y = p[1] + p[2]*exp(-(p[3]-p[3])^2 / (2*p[4]^2))


    E = calcFieldProportionality(data) .*1000
    y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]


    SNR = maximum(y) / minimum(y)
    push!(SNR_list, SNR)
    println(SNR_list)
end

scatter!(power_list, SNR_list, xlabel = "Power Level [dBm]", ylabel = "Signal to noise ratio")
png("powerComp3_SNR")

data = readMeasurement("2D_CristalRB3-07_SNR_P-3_2023-06-06_1.jld2")
plotGaussianFit(data, -7)


#dataErdem = readMeasurement("2D_CristalRB3-07_SNR_P7_2023-06-06_1.jld2")




#=
for i in 1:45
    deleteTrace(vna, i)
end
=#



