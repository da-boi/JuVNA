
using Dragoon; import Dragoon.move
using Dates
using Plots
using BoostFractor

include("stat utils.jl")


freqs = genFreqs(22.025e9,50e6; length=50)
freqsplot = genFreqs(22.025e9,150e6; length=1000)


n = 80
d0 = findpeak(22.025e9,n; dev=0.2,gran=100000)
p0 = dist2pos(ones(n)*d0);

b = AnalyticalBooster(p0,n,1e-3,24.,0.,1e-4,2.,now(),now(),0.);



move(b,p0; additive=false)

hist = initHist(b,101,freqs,ObjAnalytical)
b.summeddistance = 0;

trace = nelderMead(b,hist,freqs,
    1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-9,
    ObjAnalytical,
    # InitSimplexRegular(5e-5),
    InitSimplexCoord(5e-5),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=100000,
    showtrace=true,
    showevery=1000,
    unstuckisiter=true,
    resettimer=true); 0


dneldermead80 = copy(b.pos)
@save "spacings_sim_ann_80.jld2" dneldermead80
    

p = analyse(hist,trace,freqsplot; div=10,freqs=freqs,ylim=[-1000,100_000])

savefig(p[1],"NM_80_boost.pdf")
savefig(p[2],"NM_80_trace.pdf")
savefig(p[3],"NM_20_trace_dist.pdf")
savefig(p[5],"NM_20_hist.pdf")
savefig(p[6],"NM_20_hist_dist.pdf")





move(b,p0; additive=false)

hist = initHist(b,101,freqs,ObjAnalytical)
b.summeddistance = 0.

T = collect(range(5; length=100001,stop=0.));
trace, term = simulatedAnnealing(b,hist,freqs,T,50e-6,
    ObjAnalytical,
    UnstuckDont;
    maxiter=length(T),
    nreset=5000,
    nresetterm=0,
    showtrace=true,
    unstuckisiter=true,
    traceevery=1,
    resettimer=true,
    returntimes=true,
    showevery=5000);

p = analyse(hist,trace[1:end-1],freqsplot; div=10,freqs=freqs,ylim=[-1000,100_000])

dsimann80 = copy(b.pos)
@save "spacings_sim_ann_80.jld2" dsimann80

savefig(p[1],"SA_80_boost.pdf")
savefig(p[2],"SA_80_trace.pdf")
savefig(p[3],"SA_20_trace_dist.pdf")
savefig(p[7],"SA_20_hist.pdf")
savefig(p[6],"SA_20_hist_dist.pdf")



move(b,p0; additive=false)

hist = initHist(b,100001,freqs,ObjAnalytical)
b.summeddistance = 0.

trace = linesearch(b,hist,freqs,1e-7,
    ObjAnalytical,
    SolverSteep,
    Derivator1(1e-9,"double"),
    StepNorm("unit"),
    SearchExtendedSteps(1000),
    UnstuckRandom(1e-5,-60000);
    ϵgrad=0.,maxiter=Int(5000),showtrace=true,
    resettimer=true,showevery=100);



p = analyse(hist,trace,freqsplot; div=10,freqs=freqs)

savefig(p[1],"SD_20_boost.pdf")
savefig(p[2],"SD_20_trace.pdf")
savefig(p[3],"SD_20_trace_dist.pdf")
savefig(p[5],"SD_20_hist.pdf")
savefig(p[6],"SD_20_hist_dist.pdf")





move(b,p0; additive=false)

hist = initHist(b,100001,freqs,ObjAnalytical)
b.summeddistance = 0.

trace, term = linesearch(b,hist,freqs,1e-6,
            ObjAnalytical,
            SolverHybrid("inv",0,10e-6,1),
            Dragoon.Derivator2_(1e-6,1e-6,"double"),
            StepNorm("unit"),
            SearchExtendedSteps(200),
            # UnstuckDont;
            UnstuckRandom(1e-5,-13500);
            ϵgrad=0.,maxiter=Int(300),showtrace=true,
            resettimer=true,returntimes=true);


p = analyse(hist,trace,freqsplot; div=10,freqs=freqs)

savefig(p[1],"HY_20_boost.pdf")
savefig(p[2],"HY_20_trace.pdf")
savefig(p[3],"HY_20_trace_dist.pdf")
savefig(p[5],"HY_20_hist.pdf")
savefig(p[6],"HY_20_hist_dist.pdf")



















#number of discs in the booster
n = 3

#initial disc configuration
#findpeak tries to find an equidistant configuration with a peak at f
fc=19.0e9;
df=5e6;
initdist = findpeak(fc,n;eps=9.35,tand=0.,thickness=2e-3,gran=10000,dev=0.4)

#generate frequencies for calculation and for plotting
freqs = genFreqs(fc,df; length=101) #optimize on these frequencies
freqsplot = genFreqs(fc,5*df; length=10001)

#initialize physical properties of the booster
#booster = AnalyticalBooster(initdist)

 
d0 = initdist
p0 = dist2pos(ones(n)*d0; thickness=2e-3);

booster = AnalyticalBooster(p0,n,1e-3,24.,0.,1e-3,2.,now(),now(),0.);


booster.tand = 0.
booster.epsilon=9.35
booster.thickness=2e-3


move(booster,p0; additive=false)

hist = initHist(booster,10000,freqs,ObjAnalytical)
booster.summeddistance = 0;

trace = nelderMead(booster,hist,freqs,
    1.,1+2/booster.ndisk,0.75-1/(2*booster.ndisk),1-1/(booster.ndisk),1e-9,
    ObjAnalytical,
    InitSimplexRegular(100e-6),
    # InitSimplexCoord(1000e-6),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=1000,
    showtrace=true,
    showevery=100,
    unstuckisiter=true,
    resettimer=true); 0

plot(freqsplot/1e9,boost1d(pos2dist(booster.pos; thickness=2e-3),freqsplot; tand=booster.tand,eps=booster.epsilon,
    thickness=booster.thickness),label="optimized")
plot!(freqsplot/1e9,boost1d(pos2dist(p0; thickness=2e-3),freqsplot; tand=booster.tand,eps=booster.epsilon,
    thickness=booster.thickness),label="initial")
vline!([freqs[1],freqs[end]]/1e9; c=:black,linestyle=:dash,label="")