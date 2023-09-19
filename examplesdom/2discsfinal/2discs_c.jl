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

include("utils.jl")

# ======================================================================================================================

vna = connectVNA();

clearBuffer(vna)
setCalibration(vna,"{58DE2545-34A1-49C4-8B5D-59D0B5E1435B}")

setFrequencies(vna,20.31e9,1.5e9)
setPowerLevel(vna,0)
setAveraging(vna,false)
setIFBandwidth(vna,Int(100e3))

send(vna, "CALCulate1:PARameter:SELect 'CH1_S11_1';*OPC?\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STATe ON\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STARt 36e-10;*OPC?\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STOP 9e-9;*OPC?\n")
send(vna, "CALCulate:MEASure:FORMat MLIN\n")

setSweepPoints(vna,2*128)
freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

send(vna, "FORMat:DATA REAL,64;*OPC?\n")
send(vna, "FORMat:BORDer SWAPPed;*OPC?\n")
send(vna, "SENSe:SWEep:MODE SINGLe;*OPC?\n")

getTraceM(vna)




function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    # sleep(1)

    ref = getTraceM(vna,100; nfreqs=length(freqs))

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
# @time getTrace(vna);
@time getTraceM(vna);
@time getTraceM(vna,10; nfreqs=256);

# ======================================================================================================================
### scan
# @load "2_discs_c_scan_20p3G_peak_11_09.jld2"

move(b,p0; additive=false)

ref0 = getTraceM(vna,100; nfreqs=length(freqs))
objFR(ref) = ObjRefRef(ref,ref0)

steps = 20; dx = 2e-3;

histscan = initHist(b,(2*steps+1)^2+1,freqs,objFR(ref0));
updateHist!(b,histscan,freqs,objFR(ref0))
R = zeros(ComplexF64,2*steps+1,2*steps+1,length(ref0))

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: $i")
    
    move(b,p0+[i*dx/steps,j*dx/steps]; additive=false)
    
    ref = getTraceM(vna,100; nfreqs=length(freqs))
    updateHist!(b,histscan,freqs,objFR(ref))
    R[i+steps+1,j+steps+1,:] = ref
end

scan = makeScan(histscan; clim=(-0.25,1.15),n=steps)
# makeScan1(histscan; clim=(0,14),n=steps)

# @save "2_discs_c_scan_20p3G_peak_19_09_.jld2" ref0 histscan R freqs
saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data",ref0,histscan,R,freqs)
saveScan("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data",scan)

# ======================================================================================================================
### optimization linesearch steepest

move(b,p0; additive=false)

ref0 = getTraceM(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histls = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histls,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)
b.summeddistance = 0
@time tracels = linesearch(b,histls,freqs,10e-6,
    objF,
    SolverSteep,
    Derivator1(5e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(50),
    UnstuckRandom(1e-4,1);
    ϵgrad=0.,maxiter=Int(10),showtrace=true,
    resettimer=true);

plotPath(scan,histls,p0)
analyse(histls,tracels,freqs)

# ======================================================================================================================
### optimization linesearch newton


move(b,p0; additive=false)

ref0 = getTraceM(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histlsn = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histlsn,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)
b.summeddistance = 0
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



plotPath(scan,histlsn,p0)
analyse(histlsn,tracelsn,freqs)


# ======================================================================================================================
### optimization linesearch hybrid


move(b,p0; additive=false)

ref0 = getTraceM(vna,20)
objF = ObjRefVNA(vna,ref0)

histlsn = initHist(b,10001,freqs,objFR(ref0));
updateHist!(b,histlsn,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)
b.summeddistance = 0
@time tracelsn = linesearch(b,histlsn,freqs,10e-6,
    objF,
    SolverHybrid("inv",0,10e-6,1),
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

ref0 = getTraceM(vna,20)
objF = ObjRefVNA(vna,ref0)

histsa = initHist(b,1001,freqs,objFR(ref0));
updateHist!(b,histsa,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

T = collect(range(1,0,1000))
b.summeddistance = 0
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

ref0 = getTraceM(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histnm = initHist(b,1001,freqs,objFR(ref0));
updateHist!(b,histnm,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

b.summeddistance = 0
tracenm = nelderMead(b,histnm,freqs,
    1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-6,
    objF,
    Dragoon.InitSimplexRegular(0.0005,),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=20,
    showtrace=false,
    showevery=1,
    unstuckisiter=true,
    forcesimplexobj=false,
    resettimer=true);

plotPath(scan,histnm,p0)
plotPath(scan,tracenm,p0; showsimplex=true)

analyse(histnm,tracenm,freqs)


