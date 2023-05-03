using Plots
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


#bilder = 0

file = JSON.parsefile("measurement.json")
freq = file["freq"][:]

rawdata = file["data"][:]
S_unperturbed = file["data"][1]

#=
if bilder == 1
    println("MOIN")
    plot()
    for i = 1:50
        plot!(rawdata[i,:])
        println(i)
    end
    plot!()
end
=#
keys(file)
length(file["data"])


plot()
for i = 1:50
    plot!(rawdata[i,:])
    println(i)
end
plot!()



function calcFieldProportionality(S_perturbed::Float64, S_unperturbed::Float64, frequency::Float64)
    return Float64(sqrt(abs( (S_perturbed - S_unperturbed) / frequency / 6.28 )))
end



function calcFieldProportionality(S_perturbed::Vector{Any}, S_unperturbed::Vector{Any}, frequency::Vector{Any})::Vector{Any}
    ret = Float64[]

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i], S_unperturbed[i], frequency[i]))
    end

    return ret
end


heatmapdata = zeros(Int64, length(rawdata), length(freq))

# testmatrix = [[rawdata[1][1],rawdata[2][1]]  [rawdata[1][2],rawdata[2][2]] [rawdata[1][3],rawdata[2][3]]]
testmatrix = hcat(rawdata...)

filename = "newfileData.txt" 
file = open(filename, "w")  
writedlm(file, testmatrix, ',')
close(file)

testmatrix


heatmap(testmatrix)

#plot(heatmapdata)
