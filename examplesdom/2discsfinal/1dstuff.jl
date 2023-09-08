using Dragoon
using Plots
using BoostFractor

function groupDelay(ref::Vector{ComplexF64},freqs::Vector{Float64})
    if length(ref) != length(freqs)
        return error("Array lengths don't match up.")
    end

    r_ = abs2.(ref)

    return (r_[2:end]-r_[1:end-1])./(freqs[2:end]-freqs[1:end-1])
end

freqs = genFreqs(10.025e9,2e9; length=1000)

d0 = findpeak(10.025e9,2; eps=9.4,thickness=1e-3,dev=0.4,gran=10000)

d = ones(2)*d0

b1 = boost1d(d,freqs; eps=9.4,tand=1e-5)
r1 = Dragoon.ref1d(d,freqs; eps=9.4,tand=1e-5)

plot(freqs,b1); vline!([10.025e9])


plot(freqs,abs.(r1))

plot((freqs[2:end]+freqs[1:end-1])/2,groupDelay(r1,freqs))


plot(freqs,real.(r1))
plot!(freqs,imag.(r1))
