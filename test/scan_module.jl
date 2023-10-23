include("../src/scan.jl")
using .Scan

getCurrentPosition(motor="Monica")

scan(22000, 26000; stepSize=1000, file="data.jld2", motor="Monica")