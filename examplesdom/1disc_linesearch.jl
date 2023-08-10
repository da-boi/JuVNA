using Dragoon
using Dates
using Plots
using JLD2


include("../src/vna_control.jl");
include("../src/JuXIMC.jl");
include("../examplesdom/dragoonstuff.jl");

include("../examplesdom/stages.jl");

infoXIMC();

devcount, devenum, enumnames =
    setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184");

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

# closeDevice(D[2],D[3],D[4])
closeDevice(D[2])
D = D[1:1]

getPosition(D,stagecals)



# =========================================================================

vna = connectVNA()
setPowerLevel(vna,9)
setAveraging(vna,false)
setFrequencies(vna,20.00e9,3e9)
setSweepPoints(vna,128)
setIFBandwidth(vna,Int(100e6))
# setFormat2Log(vna)
setCalibration(vna,"{483B25B2-6FE9-483E-8A93-0527B8D277E2}")
# instrumentSimplifiedSetup(vna)

freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

# check vna setup


function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    ref = getTrace(vna)

    return sum(abs.(ref-ref0))
end

function objRefRef(booster::Booster,freqs::Vector{Float64},(ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})
    return sum(abs.(ref-ref0))
end

ObjRefVNA(vna,ref0) = Callback(objRefVNA,(vna,ref0))
ObjRefRef(ref,ref0) = Callback(objRefRef,(ref,ref0))

# =========================================================================

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices, τ=1e-3,ϵ=9.1,maxlength=0.2);

# =========================================================================

homeZero(b)
move(b,[0.05]; additive=true)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)



move(b,[0.005]; additive=true)
hist = initHist(b,1001,freqs,objF);

trace = linesearch(b,hist,freqs,1e-4,
                    objF,
                    SolverSteep,
                    Derivator1(1e-4,"double"),
                    StepNorm("unit"),
                    SearchExtendedSteps(100),
                    UnstuckDont;
                    ϵgrad=0.,maxiter=Int(1e2),showtrace=true,
                    resettimer=true);

plot(reverse((x->x.objvalue).(hist)))
plotRef(ref0; freqs=freqs)
plotRef(getTrace(vna); freqs=freqs)

analyse(hist,trace,freqs)

@save "1_disc_opt_steep_trace_hist_middle.jld2" ref0 trace hist freqs

# =========================================================================