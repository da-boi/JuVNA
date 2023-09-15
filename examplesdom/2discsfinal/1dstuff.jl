using Pkg
Pkg.add(url="https://github.com/bergermann/Dragoon.jl.git")
Pkg.update()



using Dragoon
using Plots
using BoostFractor
import Dragoon: move


freqs = genFreqs(20.3e9,1.5e9; length=128);
# d0 = findpeak(20.3e9,2; eps=9.4,tand=1e-3,thickness=1e-3,dev=0.4,gran=10000)



p0 = [0.013,0.027]*1.114





b = AnalyticalBooster(p0,2,1e-3,9.4,1e-3,1e-4,0.2,
    Dragoon.unow(),Dragoon.unow(),0)

ref0 = getRef1d(b,freqs)
Obj = ObjRefLin(ref0)

move(b,p0; additive=false)

steps = 200; dx = 2e-3;

histscan = initHist(b,(2*steps+1)^2+1,freqs,Obj);
updateHist!(b,histscan,freqs,Obj)

R = zeros(ComplexF64,2*steps+1,2*steps+1,128)

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: $i")

    move(b,p0+[i*dx/steps,j*dx/steps]; additive=false)
    
    ref = getRef1d(b,freqs)
    updateHist!(b,histscan,freqs,Obj)
    R[i+steps+1,j+steps+1,:] = ref
end

scan = makeScan(histscan; n=steps,l=dx*1e3,clim=(-1,2.3))


# ==============================================================================


move(b,p0; additive=false)

histlsn = initHist(b,100001,freqs,Obj);
updateHist!(b,histlsn,freqs,Obj)

move(b,[-0.001,-0.0000]; additive=true)

@time tracelsn = linesearch(b,histlsn,freqs,-1e-6,
    Obj,
    SolverNewton("cholesky"),
    Derivator2(1e-9,1e-9,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(100),
    # SearchStandard(0,100),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(100),showtrace=true,
    resettimer=true);

plotPath(scan,histlsn,p0; u=1e-3,l=2)

# analyse(histlsn,tracelsn,freqs)


# ==============================================================================


move(b,p0; additive=false)

histhyb = initHist(b,100001,freqs,Obj);
updateHist!(b,histhyb,freqs,Obj)

move(b,[-0.000,-0.002]; additive=true)

@time tracehyb = linesearch(b,histhyb,freqs,10e-6,
    Obj,
    SolverHybrid("inv",-0.00,1e-6,1),
    Derivator2(1e-9,1e-9,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(100),
    # SearchStandard(0,100),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(100),showtrace=true,
    resettimer=true);

plotPath(scan,histhyb,p0; u=1e-3,l=2)

# analyse(histlsn,tracelsn,freqs)


# ==============================================================================

