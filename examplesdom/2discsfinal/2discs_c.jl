using Pkg
Pkg.add(url="https://github.com/bergermann/Dragoon.jl.git")
Pkg.update()


cd("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\Julia Files\\JuXIMC.jl")

using Dragoon
using Dates
using Plots
using JLD2
using LaTeXStrings


include(joinpath(pwd(),"src/vna_control.jl"));
include(joinpath(pwd(),"src/JuXIMC.jl"));
include(joinpath(pwd(),"examplesdom/dragoonstuff.jl"));

include("stages2discs_c.jl");

# ======================================================================================================================

vna = connectVNA();

# setSweepPoints(vna,128)
send(vna, "FORMat:DATA REAL,64\n") # Set the return type to a 64 bit Float
send(vna, "FORMat:BORDer SWAPPed;*OPC?\n") # Swap the byte order and wait for the completion of the commands
send(vna, "SENSe:AVERage:STATe ON;*OPC?\n")
send(vna, "SENSe:AVERage:COUNt 10;*OPC\n")
send(vna, "SENS:SWE:GRO:COUN 20;*OPC?\n")

getTrace(vna; set=true)

getTraceG(vna,10; set=true)



freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    # sleep(1)

    ref = sum([getTrace(vna) for i in 1:20])/20

    return sum(abs.(ref-ref0))
end

function objRefRef(booster::Booster,freqs::Vector{Float64},(ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})
    return sum(abs.(ref-ref0))
end

ObjRefVNA(vna,ref0) = Callback(objRefVNA,(vna,ref0))
ObjRefRef(ref,ref0) = Callback(objRefRef,(ref,ref0));

# ======================================================================================================================

infoXIMC();

D = requestDevices("Motor 7","Monica");

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders,stagehomes);
b = PhysicalBooster(devices; τ=1e-3,ϵ=9.4,maxlength=0.2);

# homeHome(b)

p0 = [0.013,0.027]
move(b,p0; additive=false);
# @time getTraceG(vna);
@time getTrace(vna);

# ======================================================================================================================
### scan
# @load "2_discs_c_scan_20p3G_peak_11_09.jld2"

move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

steps = 20

histscan = initHist(b,(2*steps+1)^2+1,freqs,objFR(ref0));
updateHist!(b,histscan,freqs,objFR(ref0))
R = zeros(ComplexF64,2*steps+1,2*steps+1,length(ref0))

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: $i")

    move(b,p0+[i*0.0001,j*0.0001]; additive=false)
    
    ref = getTraceG(vna,10)
    updateHist!(b,histscan,freqs,objFR(ref))
    R[i+steps+1,j+steps+1,:] = ref
end

scan = makeScan(histscan; clim=(0,1.6))

@save "2_discs_c_scan_20p3G_peak_11_09_zoom.jld2" ref0 histscan R freqs

# ======================================================================================================================
### optimization linesearch steepest

move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histls = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histls,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

@time tracels = linesearch(b,histls,freqs,10e-6,
    objF,
    SolverSteep,
    Derivator1(5e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(20),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(20),showtrace=true,
    resettimer=true);

plotPathHist(histls,"2_discs_c_scan_20p3G_peak_11_09.jld2"; clim=(-0.6,1.6))
plotPathTrace(tracels,"2_discs_c_scan_20p3G_peak_11_09.jld2"; clim=(-0.6,1.6))
analyse(histls,tracels,freqs)

# ======================================================================================================================
### optimization linesearch newton


move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histlsn = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histlsn,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

@time tracelsn = linesearch(b,histlsn,freqs,-10e-6,
    objF,
    SolverNewton("inv"),
    Derivator2(5e-6,10e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(10),
    # SearchStandard(0,50),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(5),showtrace=true,
    resettimer=true);



plotPathHist(histlsn,"2_discs_c_scan_20p3G_peak_11_09.jld2"; clim=(-0.6,1.6))
plotPathTrace(tracelsn,"2_discs_c_scan_20p3G_peak_11_09.jld2"; clim=(-0.6,1.6))
analyse(histlsn,tracelsn,freqs)


# ======================================================================================================================
### optimization linesearch hybrid


move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histlsn = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histlsn,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

@time tracelsn = linesearch(b,histlsn,freqs,10e-6,
    objF,
    Dragoon.SolverHybrid("inv",0,10e-6,1),
    Derivator2(5e-6,10e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(30),
    # SearchStandard(0,50),
    UnstuckRandom(1e-5,1);
    ϵgrad=0.,maxiter=Int(20),showtrace=true,
    resettimer=true);


plotPath(scan,histlsn,p0)

analyse(histlsn,tracelsn,freqs)




# ======================================================================================================================
### optimization simulated annealing

p0 = [0.013,0.027]

move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histsa = initHist(b,1001,freqs,objFR(ref0));
updateHist!(b,histsa,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

T = collect(range(1,0,1000))

@time tracesa = simulatedAnnealing(b,histsa,freqs,T,100e-6,
    objF,
    UnstuckDont;
    maxiter=length(T),
    showtrace=true,
    showevery=trunc(Int64,length(T)/20),
    unstuckisiter=true,
    traceevery=1,
    resettimer=true);

plotPathHist(histsa,"2_discs_c_scan_20p3G_peak.jld2"; clim=(-0.35,1.55))
plotPathTrace(tracesa[1:end-1],"2_discs_c_scan_20p3G_peak.jld2";  clim=(-0.35,1.55))
analyse(histsa,tracesa,freqs)


# ======================================================================================================================
### optimization nelder mead


p0 = [0.013,0.027]

move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histnm = initHist(b,1001,freqs,objFR(ref0));
updateHist!(b,histnm,freqs,objFR(ref0))

# move(b,[0.0,0.001]; additive=true)

tracenm = nelderMead(b,histnm,freqs,
    1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-6,
    objF,
    Dragoon.InitSimplexRegular(0.001,),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=10,
    showtrace=true,
    showevery=1,
    unstuckisiter=true,
    forcesimplexobj=true,
    resettimer=true);

plotPath(scan,histnm,p0)
plotPath(scan,tracenm,p0; showsimplex=true)

analyse(histnm,tracenm,freqs)


import Dragoon: getSimplexSize, InitSimplexRegular
const Dragoon.InitSimplexRegular(d) = Callback(Dragoon.initSimplexRegular,(d,))


function Dragoon.getSimplexSize(x::Matrix{Float64},f::Vector{Float64})
    idx = argmin(f)

    s = 0

    for i in eachindex(f)
        if i == idx; continue; end

        d = pNorm(x[:,i]-x[:,idx])

        if d > s
            s = d
        end
    end

    return s
end