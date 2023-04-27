using Plots

include("analysis.jl")
include("binaryIO.jl")

meas::Measurement = readMeasurement("test.data")

E = calcFieldProportionality(meas.data, meas.freq)

E = Matrix{Float64}([1 2; 2 0])

gr()
heatmap(1:size(E,1), 1:size(E,2), E,
    c=cgrad([:blue, :white,:red, :yellow]),
    xlabel="x in 500 Steps", ylabel="f in GHz", title="Feldstärke"
)