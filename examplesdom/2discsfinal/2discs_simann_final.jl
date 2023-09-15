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
send(vna, "SENS:SWE:GRO:COUN 12;*OPC?\n")

getTraceG(vna,10; set=true)



freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    # sleep(1)

    ref = getTraceG(vna,10)

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

p0 = [0.013,0.027]
move(b,p0; additive=false);
@time getTraceG(vna);

dx = [-1,-0.5,0,0.5,1]*1e-3

# ======================================================================================================================
### optimization simulated annealing

Traces = []; Hists = []; Times = []; DX = []
T = collect(range(1,0,1001))

for j in 1:5
    for i in 1:5
        move(b,p0; additive=false)
        
        ref0 = getTraceG(vna,10)
        objF = ObjRefVNA(vna,ref0)
        objFR(ref) = ObjRefRef(ref,ref0)
        
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

        push!(Traces,tracesa); push!(hists,histsa); push!(Times,termsa); push!(DX,(dx[i],dx[j]));
    end
end
