using JLD2
using Plots
using Statistics
using LaTeXStrings

@load "nick data.jld2"

freqs = data.freq

freqs[78]

R = zeros(ComplexF64,length(data.data),128)

for i in eachindex(data.data)
    R[i,:] = data.data[i]
end

Obj = zeros(Float64,length(data.data))

for i in eachindex(data.data)
    Obj[i] = sum(abs.(R[i,:]-R[1,:]))
end

p1 = plot(abs.(R[:,78]); legend=false,linewidth=0.2)
xlabel!("Measurement")
ylabel!("Reflectivity "*L"|R|")

p2 = plot(Obj; legend=false,linewidth=0.2)
xlabel!("Measurement")
ylabel!("Objective value "*L"f_R")

savefig(p1,"nick ref.pdf")
savefig(p2,"nick obj.pdf")