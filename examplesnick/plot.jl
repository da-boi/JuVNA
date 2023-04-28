using Plots

include("analysis.jl")
include("binaryIO.jl")

meas::Measurement = readMeasurement("continous_zahnseide_300MHz.data")

E = calcFieldProportionality(meas.data, meas.freq)

gr()
heatmap(1:size(E,1), meas.freq, transpose(E),
    c=cgrad([:blue, :cyan, :yellow, :red]),
    xlabel="x", ylabel="f", title="Feldstärke"
)