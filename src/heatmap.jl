using Plots
using CSV
using DataFrames
using DelimitedFiles

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




