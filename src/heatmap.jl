using Plots
using CSV
using DataFrames
using DelimitedFiles
using JSON


#=
plot()

data =[]

filename = "newfile.csv" 
file = open(filename, "r")  
data  = readdlm(file, ',', Float64)

println(typeof(data))
close(file)


for i = 1:50
    plot!(data[i,:])
    println(i)
end
plot!()


=#

plot == 0

file = JSON.parsefile("measurement.json")
freq = file["freq"][:]

rawdata = file["data"][:]

if plot == 1
    plot()
    for i = 1:50
        plot!(rawdata[i,:])
        println(i)
    end
    plot!()
end

keys(file)
length(file["data"])






function calcFieldProportionality(S_perturbed::Float64, S_unperturbed::Float64, frequency::Float64)
    return Float64(sqrt(abs( (S_perturbed - S_unperturbed) / frequency / 6.28 )))
end

function calcFieldProportionality(S_perturbed::Vector{Float64}, S_unperturbed::Vector{Float64}, frequency::Vector{Float64})::Vector{Float64}
    ret = Float64[]

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i], S_unperturbed[i], frequency[i]))
    end

    return ret
end

calcFieldProportionality

typeof(ret)