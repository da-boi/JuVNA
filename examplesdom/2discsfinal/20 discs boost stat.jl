
using Dragoon; import Dragoon.move

const InitSimplexRegular(d) = Callback(initSimplexRegular,(d,))


using Plots
using BoostFractor


freqs = genFreqs(22.025e9,50e6; length=10)
freqsplot = genFreqs(22.025e9,150e6; length=1000)


n = 20
d0 = findpeak(22.025e9,n)
p0 = dist2pos(ones(n)*d0)

b = AnalyticalBooster(d0); b.tand = 0.;


sigx = 10e-6
N = 100

for i in 1:N
    (i%(N/10) == 0) && println("\ni: ",i,"\n")

    (i == 1) && (Term = [])

    move(b,p0+randn(n)*sigx; additive=false)

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

    push!(Term,term)
end

T = collect(range(100; length=5001,stop=50));

for i in 1:N
    (i%(N/10) == 0) && println("\ni: ",i,"\n")

    (i == 1) && (Term = [])

    move(b,p0+randn(n)*sigx; additive=false)

    hist = initHist(b,100,freqs,ObjAnalytical)
    b.summeddistance = 0.

    trace, term = simulatedAnnealing(b,hist,freqs,T,100e-6,
        ObjAnalytical,
        UnstuckDont;
        maxiter=length(T),
        nreset=200,
        nresetterm=10,
        showtrace=false,
        unstuckisiter=true,
        traceevery=1,
        resettimer=true,
        returntimes=true);

    push!(Term,term)
end

plotTerm(Term)

function plotTerm(T)
    obj = [abs(t[1]) for t in T]
    # ttot = [t[2][1] for t in T]
    dist = [t[2][2] for t in T]

    # display(scatter(ttot,obj))
    display(scatter(dist,obj; legend=false,markersize=1))
end



