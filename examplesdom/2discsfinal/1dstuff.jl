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


# args = (Δx1,Δx2,mode)
function secondDerivative_(g,h,booster,hist,freqs,objFunction,args)
    updateHist!(booster,hist,freqs,objFunction; force=true)

    p0 = copy(booster.pos)

    move(booster,[(1,args[1])])
    
    if args[3] == "double"
        for i in 1:booster.ndisk
            updateHist!(booster,hist,freqs,objFunction; force=true)
            move(booster,[(i,-2*args[1])])
            updateHist!(booster,hist,freqs,objFunction; force=true)

            g[i] = (hist[2].objvalue-hist[1].objvalue)/(2*args[1])

            if i != booster.ndisk
                move(booster,[(i,args[1]),(i+1,args[1])])
            else
                # move(booster,[(i,args[1])])
                move(booster,p0; additive=false)
            end
        end

        for i in 1:booster.ndisk, j in 1:booster.ndisk
            if i == j
                move(booster,[(i,args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)
                
                move(booster,[(i,-args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                move(booster,[(i,-args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                h[i,i] = (hist[3].objvalue-2*hist[2].objvalue+hist[1].objvalue)/(args[2]^2)

                move(booster,[(i,args[2])])
                move(booster,p0; additive=false)
            else
                # x + h*e_i + h*e_j
                move(booster,[(i,args[2]),(j,args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                # x + h*e_i - h*e_j
                move(booster,[(j,-2*args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                # x - h*e_i + h*e_j
                move(booster,[(i,-2*args[2]),(j,2*args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                # x - h*e_i - h*e_j
                move(booster,[(j,-2args[2])])
                updateHist!(booster,hist,freqs,objFunction; force=true)

                h[i,j] = (hist[4].objvalue-hist[3].objvalue-
                            hist[2].objvalue+hist[1].objvalue)/(4*args[2]^2)

                # h[i,j] = h[j,i] = (hist[4].objvalue-hist[3].objvalue-
                #             hist[2].objvalue+hist[1].objvalue)/(4*args[2]^2)

                move(booster,[(i,args[2]),(j,args[2])])
                move(booster,p0; additive=false)
            end
        end
    else
        0
    end
end

const Derivator2_(Δx1,Δx2,mode) = Callback(secondDerivative_,(Δx1,Δx2,mode))


# ==============================================================================

# args = (mode,ϵls,αtest,ntest)
function solverHybrid(booster::Booster,hist::Vector{State},freqs::Vector{Float64},
        objFunction::Callback,p::Vector{Float64},g::Vector{Float64},h::Matrix{Float64},
        trace::Vector{Dragoon.LSTrace},i::Int,
        (mode,ϵls,αtest,ntest)::Tuple{String,Real,Real,Int})

    if mode == "cholesky"
        try
            C = cholesky(h)

            p[:] = inv(C.U)*inv(C.L)*g
        catch e
            println("Hessian not Cholesky decomposable: ", e)
            println("Falling back to standard inversion.")
            
            p[:] = inv(h)*g
        end
    else
        p[:] = inv(h)*g
    end

    p[:] = p/pNorm(p)

    p0 = copy(booster.pos)
    updateHist!(booster,hist,freqs,objFunction)

    # test forward
    for i in ntest
        move(booster,αtest*p; additive=true)
        updateHist!(booster,hist,freqs,objFunction)

        if hist[1].objvalue > hist[i+1].objvalue+ϵls
            move(booster,p0)
            updateHist!(booster,hist,freqs,objFunction)

            break
        end

        if i == ntest
            println("Forward test successfull.")
            move(booster,p0)
            updateHist!(booster,hist,freqs,objFunction)

            return
        end
    end

    # test backward
    for i in ntest
        move(booster,-αtest*p; additive=true)
        updateHist!(booster,hist,freqs,objFunction)

        if hist[1].objvalue > hist[i+1].objvalue+ϵls
            move(booster,p0)
            updateHist!(booster,hist,freqs,objFunction)

            break
        end

        if i == ntest
            println("Backward test successfull.")
            move(booster,p0)
            updateHist!(booster,hist,freqs,objFunction)

            p[:] = -p[:]
            
            return
        end
    end

    # fall back to steepest descend
    println("Falling back to steepest descend.")
    p[:] = -g

    return
end

const SolverHybrid(mode::String,ϵls::Real,αtest::Real,ntest::Int) =
    Callback(solverHybrid,(mode,ϵls,αtest,ntest))
