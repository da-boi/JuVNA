include("../src/scan.jl")
using .Scan

# setMicroStepMode(D, mode=MICROSTEP_MODE_FRAC_256)

scan(stepSize=100.0, steps=10, file="data.jld2", motor="Monica")