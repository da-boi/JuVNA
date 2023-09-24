
using Dragoon; import Dragoon.move
using Dates
using Plots
using BoostFractor

include("stat utils.jl")


freqs = genFreqs(22.025e9,50e6; length=50)
freqsplot = genFreqs(22.025e9,150e6; length=1000)


n = 20
d0 = findpeak(22.025e9,n)
p0 = dist2pos(ones(n)*d0);

b = AnalyticalBooster(d0); b.tand = 0.;



move(b,p0; additive=false)

hist = initHist(b,10001,freqs,ObjAnalytical)
b.summeddistance = 0.

trace, term = nelderMead(b,hist,freqs,
    1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-6,
    ObjAnalytical,
    # InitSimplexRegular(5e-5),
    InitSimplexCoord(1e-5),
    DefaultSimplexSampler,
    UnstuckNew(InitSimplexRegular(1e-5),true,-15000);
    maxiter=1000,
    showtrace=true,
    unstuckisiter=true,
    resettimer=true,
    returntimes=true);



p = analyse(hist,trace,freqsplot; div=10,freqs=freqs)

savefig(p[1],"NM_20_boost.pdf")
savefig(p[2],"NM_20_trace.pdf")
savefig(p[3],"NM_20_trace_dist.pdf")
savefig(p[5],"NM_20_hist.pdf")
savefig(p[6],"NM_20_hist_dist.pdf")





move(b,p0; additive=false)

hist = initHist(b,10001,freqs,ObjAnalytical)
b.summeddistance = 0.

T = collect(range(1; length=2001,stop=0));
trace, term = simulatedAnnealing(b,hist,freqs,T,25e-6,
    ObjAnalytical,
    UnstuckDont;
    maxiter=length(T),
    nreset=50,
    nresetterm=4,
    showtrace=true,
    unstuckisiter=true,
    traceevery=1,
    resettimer=true,
    returntimes=true);

p = analyse(hist,trace[1:end-1],freqsplot; div=10,freqs=freqs)

savefig(p[1],"SA_20_boost.pdf")
savefig(p[2],"SA_20_trace.pdf")
savefig(p[3],"SA_20_trace_dist.pdf")
savefig(p[7],"SA_20_hist.pdf")
savefig(p[6],"SA_20_hist_dist.pdf")



move(b,p0; additive=false)

hist = initHist(b,100001,freqs,ObjAnalytical)
b.summeddistance = 0.

trace, term = linesearch(b,hist,freqs,1e-7,
            ObjAnalytical,
            SolverSteep,
            Derivator1(1e-6,"double"),
            StepNorm("unit"),
            SearchExtendedSteps(100),
            UnstuckRandom(1e-5,-14000);
            ϵgrad=0.,maxiter=Int(250),showtrace=true,
            resettimer=true,returntimes=true,showevery=25);



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
            UnstuckRandom(1e-5,-14000);
            ϵgrad=0.,maxiter=Int(50),showtrace=true,
            resettimer=true,returntimes=true,showevery=10);


p = analyse(hist,trace,freqsplot; div=10,freqs=freqs)

savefig(p[1],"HY_20_boost.pdf")
savefig(p[2],"HY_20_trace.pdf")
savefig(p[3],"HY_20_trace_dist.pdf")
savefig(p[5],"HY_20_hist.pdf")
savefig(p[6],"HY_20_hist_dist.pdf")