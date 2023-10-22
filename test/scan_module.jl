include("../src/scan.jl")
using .Scan

getCurrentPosition()

scan(0, 1000; stepSize=100, file="data.jld2")