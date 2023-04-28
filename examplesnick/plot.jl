using Plots

include("analysis.jl")
include("binaryIO.jl")

meas::Measurement = readMeasurement("cont.data")

E = calcFieldProportionality(meas.data, meas.freq)

#E = Matrix{Float64}([1 2; 2 0])

E = meas.data

gr()
heatmap(1:size(E,2), meas.freq, transpose(E),
    c=cgrad([:blue, :white,:red, :yellow]),
    xlabel="x", ylabel="f", title="Feldstärke"
)