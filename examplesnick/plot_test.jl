include("measurement.jl")
include("plot.jl")

m = readMeasurement("../beadpull/data/c2000_black150_al3180_2023-05-10_1.jld2")
ms = readMeasurement("../beadpull/data/s_black150_al3180_2023-05-10_1.jld2")

plotHeatmap(m; color=:jet1)
plotGaussianFit(m)
plotGaussianFit([m, ms])

m = []
push!(m, ("Cont1000", readMeasurement("../data/method")))
push!(m, ("Cont2000", readMeasurement("../data/method")))
push!(m, ("Cont4000", readMeasurement("../data/method")))
push!(m, ("Discrete", readMeasurement("../data/method")))

for e in m
    plot = plotHeatmap(e[2])
    savefig(plot)
end