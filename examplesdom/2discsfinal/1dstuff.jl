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

freqs = genFreqs(20.3e9,1.5e9; length=128)

# d0 = findpeak(10.025e9,2; eps=9.4,thickness=1e-3,dev=0.4,gran=10000)


function objRef(booster::Booster,freqs::Vector{Float64},
        (ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})

    return sum(abs.(ref-ref0))
end

ObjRefRef(ref,ref0) = Callback(objRef,(ref,ref0))



p0 = [0.013,0.027]




b = AnalyticalBooster(p0,2,1e-3,9.4,1e-3,1e-4,0.2,
    Dragoon.unow(),Dragoon.unow(),0)


Dragoon.move(b,p0; additive=false)

ref0 = getRef1d(b,freqs)
Obj = ObjRefRef(getRef1d(b,freqs),ref0)
ObjR(ref) = ObjRefRef(ref,ref0)

steps = 200

histscan = initHist(b,(2*steps+1)^2+1,freqs,Obj);
updateHist!(b,histscan,freqs,ObjR(ref0))

R = zeros(ComplexF64,2*steps+1,2*steps+1,128)

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: $i")

    Dragoon.move(b,p0+[i*0.00001,j*0.00001]; additive=false)
    
    ref = getRef1d(b,freqs)
    updateHist!(b,histscan,freqs,ObjR(ref))
    R[i+steps+1,j+steps+1,:] = ref
end

R_ = reverse(reshape((x->x.objvalue).(histscan[1:end-1]),
    (2steps+1,2steps+1))); println(log10.(extrema(R_)))

scan = contourf(-2:2/steps:2,-2:2/steps:2,log10.(R_);
    color=:turbo,levels=30,lw=0,aspect_ratio=:equal,
    clim=(-1,2.4))

xlims!((-2,2)); ylims!((-2,2))


import Dragoon: move

move(b,p0; additive=false)

ref0 = getRef1d(b,freqs)
Obj = ObjRefRef(getRef1d(b,freqs),ref0)
ObjR(ref) = ObjRefRef(ref,ref0)

histlsn = initHist(b,(2*steps+1)^2+1,freqs,Obj);
updateHist!(b,histlsn,freqs,Obj)

move(b,[0.0,0.001]; additive=true)

@time tracelsn = linesearch(b,histlsn,freqs,10e-6,
    Obj,
    SolverNewton("inv"),
    Derivator2(5e-6,10e-6,"double"),
    StepNorm("unit"),
    # SearchExtendedSteps(20),
    SearchStandard(0,50),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(5),showtrace=true,
    resettimer=true);

