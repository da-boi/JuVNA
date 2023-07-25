# using Pkg

# Pkg.add(url="https://github.com/mppmu/BoostFractor.jl.git")
# Pkg.add(url="https://github.com/bergermann/Dragoon.jl.git")
# Pkg.update()

using Dragoon
using Dates
using Plots


include("../src/vna_control.jl");
include("../src/JuXIMC.jl");
include("../examplesdom/dragoonstuff.jl");

include("../examplesdom/stages.jl");

infoXIMC();

devcount, devenum, enumnames =
    setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184");

# =========================================================================

vna = connectVNA()
# setPowerLevel(vna,-20)
# setAveraging(vna,false)
# setFrequencies(vna,20.025e9,50e6)
# setSweepPoints(vna,101)
# setIFBandwidth(vna,Int(50e6))
# setFormat2Log(vna)
instrumentSimplifiedSetup(vna)


# check type of vna!
# check vna setup


function objRefVNA(booster::Booster,freqs::Vector{Float64},args::Tuple{Any,Vector{ComplexF64}})
    ref = getDataAsBinBlockTransfer(vna)

    return sum(abs.(ref-args[1]))
end

ObjRefVNA(ref0,vna) = Callback(objRefVNA,(ref0,vna))

function getObjRef1d(booster::Booster,freqs::Vector{Float64},args::Tuple{Vector{ComplexF64}})
    return sum(abs.(ref1d(pos2dist(booster.pos; thickness=booster.thickness),
        freqs; eps=booster.epsilon,thickness=booster.thickness)-args[1]))
end

# =========================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

closeDevice(D[2],D[3],D[4])
D = D[1:1]


getPosition(D,stagecals)

# vna = connectVNA()
# instrumentSimplifiedSetup(vna)

freqs = genFreqs(22.025e9,50e6; length=10);
freqsplot = genFreqs(22.025e9,150e6; length=1000);

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices);
b.epsilon = 1.;

objF = ObjRefVNA(ref0,vna)

homeZero(b)
move(b,[0.05]; additive=true)

ref0 = getDataAsBinBlockTransfer(vna)

hist = initHist(b,100,freqs,objF);

for i in 1:100
    move(b,[0.01]; additive=true)
    updateHist!(booster,hist,freqs,objF)
end