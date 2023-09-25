using JLD2
using Plots
using Statistics
using LaTeXStrings
using Dragoon


@load "0_discs_scan_ref_and_hist_a.jld2"

freqsplot = genFreqs(20.0e9,3e9; length=128)

obj = reverse((x->x.objvalue).(hist[1:end-1]))
x = reverse((x->x.pos[1]).(hist[1:end-1])).-0.29999890625000003.+0.05



p1 = plot(freqsplot/1e9,abs.(R[250,:]); legend=false)
xlabel!("Frequency [GHz]")
ylabel!("Reflectivity "*L"|R|")



p2 = plot(x/1e-2,obj; label="physical")
xlabel!("Mirror position [cm]")
ylabel!("Objective value "*L"f_R")


ref0 = ref1d([x[250]],freqsplot; eps=1.,thickness=0.,tand=0.)


obj_ = zeros(Float64,length(x))

for i in eachindex(x)
    ref = ref1d([x[i]],freqsplot; eps=1.,thickness=0.,tand=0.)

    obj_[i] = sum(abs.(ref-ref0))
end

plot!(p2,x/1e-2,obj_; label="analytical",c=:red)

savefig(p1,"0discsref.pdf")
savefig(p2,"0discsobj.pdf")

plot!(p1,freqsplot/1e9,abs.(ref0))