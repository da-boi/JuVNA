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

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

closeDevice(D[3],D[4])
D = D[1:2]



#number of discs in the booster
n = 0

#initial disc configuration
#findpeak tries to find an equidistant configuration with a peak at f
initdist = findpeak(22.025e9,n)

#generate frequencies for calculation and for plotting
freqs = genFreqs(22.025e9,50e6; length=10) #optimize on these frequencies
freqsplot = genFreqs(22.025e9,150e6; length=1000)

#initialize physical properties of the booster
booster = AnalyticalBooster(
    [initdist],1,0.,1.,1e-3,1,DateTime(0),
    Dragoon.unow(),0.
)


#initialize storage of measurements
hist = initHist(booster,10000,freqs,ObjAnalytical)
#                           ^ length, should be at least the larger of (n^2, search steps)
;

trace = linesearch(booster,hist,freqs,booster.vmotor*1e-3,
                    ObjAnalytical,
                    SolverSteepest,
                    Derivator1(1e-6,"double"),
                    StepNorm("unit"),
                    SearchExtendedSteps(1000),
                    UnstuckDont;
                    ϵgrad=0.,maxiter=Int(1e2),showtrace=true);