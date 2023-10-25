include("../src/scan.jl")
using .Scan

data = scan(steps=10, stepSize=2, file="data.jld2", motor="Alexanderson")