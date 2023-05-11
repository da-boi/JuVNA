# for testing purposes only

using Dragoon

include("../src/vna_control.jl");
include("../src/JuXIMC.jl");
include("../examplesdom/dragoonstuff.jl");

include("../examplesdom/stages.jl");

infoXIMC();

devcount, devenum, enumnames =
    setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184");

# =========================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

# closeDevice(D[3])
D = D[1:2]


commandMove(D,[0,0],stagecals)
commandMove(D,[10,10],stagecals)

getPosition(D,stagecals)

# vna = connectVNA()
# instrumentSimplifiedSetup(vna)

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders)

b = PhysicalBooster(devices)



homeZero(b)

move(b,[0.01,0.01]; additive=true)

freqs = genFreqs(22.025e9,50e6; length=10)
freqsplot = genFreqs(22.025e9,150e6; length=1000)

hist = initHist(booster,10000,freqs,(getObjAna1d,[]))

nelderMead(booster::AnalyticalBooster,hist::Vector{State},freqs::Array{Float64},
    α::Float64,β::Float64,γ::Float64,δ::Float64,
    objFunction::Tuple{Function,Vector},
    initSimplex::Tuple{Function,Vector},
    simplexObj::Tuple{Function,Vector},
    unstuckinator::Tuple{Function,Vector};

    maxiter::Integer=Int(1e2),
    showtrace::Bool=false,
    showevery::Integer=1,
    unstuckisiter::Bool=true,
    tracecentroid::Bool=false,
    traceevery::Int=1)