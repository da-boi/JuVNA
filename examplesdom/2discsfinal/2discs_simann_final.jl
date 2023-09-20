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

    ref = getTraceM(vna,10; nfreqs=length(freqs))
    # ref = getTraceM(vna)

    return sum(abs.(ref-ref0))
end

function objRefRef(booster::Booster,freqs::Vector{Float64},(ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})
    return sum(abs.(ref-ref0))
end

ObjRefVNA(vna,ref0) = Callback(objRefVNA,(vna,ref0))

# ======================================================================================================================

infoXIMC();

D = requestDevices("Motor 7","Monica");

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders,stagehomes);
b = PhysicalBooster(devices; τ=1e-3,ϵ=9.4,maxlength=0.2);

p0 = [0.013,0.027]
move(b,p0; additive=false);
@time getTraceG(vna);

dx = [-1,-0.5,0,0.5,1]*1e-3

# ======================================================================================================================
### optimization simulated annealing

Traces = []; Hists = []; Times = []; DX = []; Ref0 = []
T = collect(range(0.1,0,1001))

for j in 1:5
    for i in 1:5
        move(b,p0; additive=false)
        
        ref0 = getTraceM(vna,100)
        objF = ObjRefVNA(vna,ref0)
        
        histsa = initHist(b,1001,freqs,objFR(ref0));
        updateHist!(b,histsa,freqs,objFR(ref0))
        
        move(b,[dx[i],dx[j]]; additive=true)

        @time tracesa, termsa = simulatedAnnealing(b,histsa,freqs,T,100e-6,
            objF,
            UnstuckDont;
            maxiter=length(T),
            nreset=50,
            nresetterm=2,
            showtrace=true,
            showevery=trunc(Int64,length(T)/20),
            unstuckisiter=true,
            traceevery=1,
            resettimer=true);

        push!(Traces,tracesa); push!(hists,histsa); push!(Times,termsa); push!(DX,(dx[i],dx[j])); push!(Ref0,ref0)
    end
end
