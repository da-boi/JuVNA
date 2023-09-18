
using Pkg
Pkg.add(url="https://github.com/bergermann/Dragoon.jl.git")
Pkg.update()

using Dragoon; import Dragoon.move
using Dates
using Plots
using BoostFractor

include("stat utils.jl")


freqs = genFreqs(22.025e9,50e6; length=10)
freqsplot = genFreqs(22.025e9,150e6; length=1000)


n = 20
d0 = findpeak(22.025e9,n)
p0 = dist2pos(ones(n)*d0);

b = AnalyticalBooster(d0); b.tand = 0.;


sigx = [1e-6,10e-6,50e-6,100e-6];
N = 1000; Term = zeros(Float64,N,4,length(sigx));

for s in eachindex(sigx)
    print("\nσx = $(sigx[s]), i: 0")

    for i in 1:N
        (i%(N/10) == 0) && print(",",i)

        move(b,p0+randn(n)*sigx[s]; additive=false)

        hist = initHist(b,100,freqs,ObjAnalytical)
        b.summeddistance = 0.

        trace, term = nelderMead(b,hist,freqs,
            1.,1+2/b.ndisk,0.75-1/(2*b.ndisk),1-1/(b.ndisk),1e-6,
            ObjAnalytical,
            # InitSimplexRegular(5e-5),
            InitSimplexCoord(1e-5),
            DefaultSimplexSampler,
            UnstuckDont;
            maxiter=10000,
            showtrace=false,
            unstuckisiter=true,
            resettimer=true,
            returntimes=true)

        Term[i,1,s] = term[1]
        Term[i,2,s] = term[2][1].value
        Term[i,3,s] = term[2][2]
        Term[i,4,s] = term[2][3].value
    end
end;

plotTerm(Term,sigx; maxt=1000,maxdist=500);

p1, p2 = plotTerm(Term,sigx; maxt=1000,maxdist=500)
savefig(p1,"20discs_nm_time.pdf")
savefig(p2,"20discs_nm_dist.pdf")

# ==============================================================================




N = 1000; Term = zeros(Float64,N,4,length(sigx));

T = collect(range(1; length=2001,stop=0));
for s in eachindex(sigx)
    print("\nσx = $(sigx[s]), i: 0")

    for i in 1:N
        (i%(N/10) == 0) && print(",",i)

        move(b,p0+randn(n)*sigx[s]; additive=false)

        hist = initHist(b,100,freqs,ObjAnalytical)
        b.summeddistance = 0.

        trace, term = simulatedAnnealing(b,hist,freqs,T,25e-6,
            ObjAnalytical,
            UnstuckDont;
            maxiter=length(T),
            nreset=50,
            nresetterm=2,
            showtrace=false,
            unstuckisiter=true,
            traceevery=1,
            resettimer=true,
            returntimes=true);

        Term[i,1,s] = term[1]
        Term[i,2,s] = term[2][1].value
        Term[i,3,s] = term[2][2]
        Term[i,4,s] = term[2][3].value
    end
end; plotTerm(Term,sigx);


p1, p2 = plotTerm1(Term,sigx)
savefig(p1,"20discs_sa_time.pdf")
savefig(p2,"20discs_sa_dist.pdf")

# ==============================================================================




N = 10; Term = zeros(Float64,N,4,length(sigx));

for s in eachindex(sigx[1:2])
    print("\nσx = $(sigx[s]), i: 0")

    for i in 1:N
        (i%(N/10) == 0) && print(",",i)

        move(b,p0+randn(n)*sigx[s]; additive=false)

        hist = initHist(b,100,freqs,ObjAnalytical)
        b.summeddistance = 0.

        trace, term = linesearch(b,hist,freqs,1e-6,
            ObjAnalytical,
            SolverSteep,
            Derivator1(1e-9,"double"),
            StepNorm("unit"),
            SearchExtendedSteps(100),
            UnstuckRandom(1e-5,-13000);
            ϵgrad=0.,maxiter=Int(300),showtrace=false,
            resettimer=true,returntimes=true);        

        Term[i,1,s] = term[1]
        Term[i,2,s] = term[2][1].value
        Term[i,3,s] = term[2][2]
        Term[i,4,s] = term[2][3].value
    end
end; plotTerm(Term,sigx);


p1, p2 = plotTerm1(Term,sigx)
savefig(p1,"20discs_sd_time.pdf")
savefig(p2,"20discs_sd_dist.pdf")



