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

setSweepPoints(vna,128)
# setSweepPoints(vna,2*128)
freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

send(vna, "FORMat:DATA REAL,64;*OPC?\n")
send(vna, "FORMat:BORDer SWAPPed;*OPC?\n")
send(vna, "SENSe:SWEep:MODE SINGLe;*OPC?\n")

# getTraceM(vna)
getTrace(vna)


# ======================================================================================================================


function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    ref = getTrace(vna,10; nfreqs=length(freqs))
    # ref = getTraceM(vna,10; nfreqs=length(freqs))
    # ref = getTraceM(vna)

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
# @time getTraceM(vna);
# @time ref0b = getTraceM(vna,100; nfreqs=length(freqs));
@time getTrace(vna);
@time getTrace(vna,100; nfreqs=length(freqs));

# ======================================================================================================================
### scan
# @load "\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\scans\\19_9_2023-13_57.jld2"

move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs));
objFR(ref) = ObjRefRef(ref,ref0)

steps = 20; dx = 2e-3;

histscan = initHist(b,(2*steps+1)^2+1,freqs,objFR(ref0));
updateHist!(b,histscan,freqs,objFR(ref0))
R = zeros(ComplexF64,2*steps+1,2*steps+1,length(ref0));

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: $i")
    
    move(b,p0+[i*dx/steps,j*dx/steps]; additive=false)
    
    # ref = getTraceM(vna,100; nfreqs=length(freqs))
    ref = getTrace(vna,100; nfreqs=length(freqs))
    updateHist!(b,histscan,freqs,objFR(ref))
    R[i+steps+1,j+steps+1,:] = ref
end

scan = makeScan(histscan; clim=(-0.1,1.55),n=steps)
# makeScan1(histscan; clim=(0,14),n=steps)

# @save "2_discs_c_scan_20p3G_peak_19_09_.jld2" ref0 histscan R freqs
saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data",ref0,histscan,R,freqs)
saveScan("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data",scan)

# ======================================================================================================================
### optimization linesearch steepest

move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histsd = initHist(b,10001,freqs,objF);
updateHist!(b,histsd,freqs,objF)

move(b,[-0.001,0.001]; additive=true)
b.summeddistance = 0
@time tracesd = linesearch(b,histsd,freqs,10e-6,
    objF,
    SolverSteep,
    Derivator1(5e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(50),
    UnstuckRandom(1e-4,2.1);
    ϵgrad=0.,maxiter=Int(20),showtrace=true,
    resettimer=true);

# histsd = histsd[250:end]
# tracesd = tracesd[1:15]
plotPath(scan,histsd,p0)
plotPath(scan,tracesd,p0)
# analyse(histnm,tracenm,freqs)

saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\","SD",scan,ref0,histsd,tracesd,freqs; p0=p0)
        
    
    
# ======================================================================================================================
### optimization linesearch newton


move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histnw = initHist(b,10001,freqs,objF);
updateHist!(b,histnw,freqs,objF)

move(b,[0,0.001]; additive=true)
b.summeddistance = 0
@time tracenw = linesearch(b,histnw,freqs,-10e-6,
    objF,
    SolverNewton("inv"),
    Derivator2(5e-6,10e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(50),
    # SearchStandard(0,50),
    UnstuckRandom(1e-4,2.1);
    ϵgrad=0.,maxiter=Int(20),showtrace=true,
    resettimer=true);




plotPath(scan,histnw,p0)
plotPath(scan,tracenw,p0)
# analyse(histnm,tracenm,freqs)

saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\","NW",scan,ref0,histnw,tracenw,freqs; p0=p0)
    


# ======================================================================================================================
### optimization linesearch hybrid
# @load "\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\optims\\HY_19_9_2023-17_23.jld2"
# histhyb = hist; tracehyb = trace


move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histhyb = initHist(b,10001,freqs,objF);
updateHist!(b,histhyb,freqs,objF)

move(b,[-0.001,0.001]; additive=true)
b.summeddistance = 0
@time tracehyb = linesearch(b,histhyb,freqs,10e-6,
    objF,
    SolverHybrid("inv",0,10e-6,1),
    Derivator2(5e-6,10e-6,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(50),
    # SearchStandard(0,50),
    UnstuckRandom(1e-4,1);
    ϵgrad=0.,maxiter=Int(20),showtrace=true,
    resettimer=true);

tracehyb = tracehyb[1:12]

plotPath(scan,histhyb[500:end],p0)
plotPath(scan,tracehyb,p0)
analyse(histhyb,tracehyb,freqs)

saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\","HY",scan,ref0,histhyb[500:end],tracehyb,freqs; p0=p0)
    


# ======================================================================================================================
### optimization simulated annealing
# @load "\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\optims\\SA_19_9_2023-16_53.jld2"
# histsa = hist; tracesa = trace

p0 = [0.013,0.027]

move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histsa = initHist(b,1001,freqs,objF);
updateHist!(b,histsa,freqs,objF)

move(b,[-0.001,0.001]; additive=true)

T = collect(range(0.1,0,201))
b.summeddistance = 0
@time tracesa = simulatedAnnealing(b,histsa,freqs,T,100e-6,
    objF,
    UnstuckDont;
    nreset=50,
    nresetterm=0,
    maxiter=length(T),
    showtrace=true,
    showevery=trunc(Int64,length(T)/20),
    unstuckisiter=true,
    traceevery=1,
    resettimer=true); tracesa = tracesa[1:end-1]

plotPath(scan,histsa,p0)
plotPath(scan,tracesa,p0)
# analyse(histnm,tracenm,freqs)

saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\","SA",scan,ref0,histsa,tracesa,freqs; p0=p0)
    
    

# ======================================================================================================================
### optimization nelder mead
# @load "\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\optims\\NM_19_9_2023-15_58.jld2"
# histnm = hist; tracenm = trace

p0 = [0.013,0.027]

move(b,p0; additive=false)

# ref0 = getTraceM(vna,100; nfreqs=length(freqs))
ref0 = getTrace(vna,100; nfreqs=length(freqs))
objF = ObjRefVNA(vna,ref0)

histnm = initHist(b,1001,freqs,objF);
updateHist!(b,histnm,freqs,objF)

move(b,[-0.001,0.001]; additive=true)

b.summeddistance = 0
tracenm = nelderMead(b,histnm,freqs,
    1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-6,
    objF,
    Dragoon.InitSimplexRegular(0.0005,),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=50,
    showtrace=true,
    showevery=1,
    unstuckisiter=true,
    forcesimplexobj=false,
    resettimer=true);

plotPath(scan,histnm,p0)
plotPath(scan,tracenm,p0; showsimplex=true)
# analyse(histnm,tracenm,freqs)

saveStuff("\\\\inst3\\data\\Benutzer\\bergermann\\Desktop\\final data\\","NM",scan,ref0,histnm,tracenm,freqs; p0=p0)

