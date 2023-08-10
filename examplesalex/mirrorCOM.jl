include("stages.jl")
include("measurement.jl")
include("plot.jl")

bead = "CristalRB3-07"
date = "2023-07-18"
mirror = "-Gold"
name::String = bead*mirror

power= -20
f_center::Float64 = 20e9
f_span::Float64 = 3e9
sweepPoints::Integer = 10000
ifbandwidth::Integer = 100e3

vna = connectVNA()
vnaParam = instrumentSimplifiedSetup(vna; calName=cals[:c3GHz_NEW], power=power, center=f_center, span=f_span, sweepPoints=sweepPoints, ifbandwidth=ifbandwidth)
#=
for j in 1:10
    S11 = Array[] 
    S11_abs = []
    storeTraceInMemory(vna, 1)
    push!(S11, getTraceFromMemory(vna, 1))
    for i in eachindex(S11[1])
        v = abs(S11[1][i])
        push!(S11_abs, log10(v^2)*10)
    end
    
    saveMeasurement(S11_abs, filename=name*string(j))
end
=#

#10 Plots overlay
plot()
for i in 1:10
    S11_abs=readMeasurement(name*string(i))
    display(plot!(S11_abs))
end



#AVERage 
S11_list = zeros(Float64, 10000)
for i in 1:10 
    S11_abs=readMeasurement(name*string(i))
    typeof(S11_abs)
    S11_list = S11_list + S11_abs
end
S11_list = S11_list/10

plot()
display(plot!(S11_list,label=name, legend=true))
savefig("filename_string")



#=
for i in 1:45
    deleteTrace(vna, i)
end
=#
