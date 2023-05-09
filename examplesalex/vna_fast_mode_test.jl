
using DelimitedFiles
include("stages.jl")
include("measurement.jl")
include("plot.jl")


### Connect to the Motor "Bigger Chungus" ###
devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

D = openDevices(enumnames,stagenames)
# checkOrdering(D,stagenames)
#closeDevices(D[1:3])
D = D[4]

### Connect to the VNA ###
power=0
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweeppoints::Integer = 128
ifbandwidth::Integer = 100e3
measurement::String = "CH1_S11_1"

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweeppoints, ifbandwidth=ifbandwidth)

@time S, f, pos, posSet = getContinousMeasurement(vna, 0, 28000; speed=2000, speedSetup=2000, stepSize=500)
meas = Measurement("speedtest", vnaParam, f, S, pos, posSet)
saveMeasurement(meas; filename="metalwire_3GHz.data")


plotHeatmap(meas)
plotGaussianFit(meas)

#meas_floss = readMeasurement("floss_3GHz.data")
#meas_metal = readMeasurement("metalwire_3GHz.data")
#plotGaussianFit([meas_floss, meas_metal])



#println(S)
#println(pos)



filename = "S.txt" 
fileS = open(filename, "w")  
writedlm(fileS, S, ',')
close(fileS)

filename = "Pos.txt" 
filePos = open(filename, "w")  

# for i in 1:length(posSet)
#     fullPos = pos[i].Position, pos[i].uPosition
#     println(fullPos)
#     #println(pos[i].Position, ';', pos[i].uPosition)
#     writedlm(filePos, fullPos; dims=(length(posSet),2))
    
# end    


p = [pos[i].Position for i in 1:length(posSet)]
up = [pos[i].uPosition for i in 1:length(posSet)]

writedlm(filePos, [p up])

close(filePos)


deleteTrace(vna, 1)
#closeDevices(D[1:4])