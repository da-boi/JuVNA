
using Dragoon; import Dragoon.move
using Dates
using Plots
using BoostFractor

include("stat utils.jl")


ref1 = [
    0.7980364538331479 - 0.6026091754640537im
    0.5722258344342472 - 0.8200960885201205im
    0.29751367307577037 - 0.9547175573608412im
    0.013002545003664823 - 0.9999154633385203im
    -0.2488873620760616 - 0.9685324367303588im
    -0.46978992381108925 - 0.8827782436634606im
    -0.6443375162188284 - 0.7647412406775141im
    -0.7753159748271924 - 0.6315735421767833im
    -0.8690824586874958 - 0.49466724169048837im
    -0.9326743750341522 - 0.3607194341239197im
    -0.97242971196007 - 0.23319617341899182im
    -0.9935310129569074 - 0.11356111259068322im
    -0.9999977214392506 - 0.002134740336053248im
    -0.9948498003392782 + 0.10136012413629629im
    -0.9803085205029861 + 0.1974720350562016im
    -0.9579801608294265 + 0.2868344669966064im
    -0.9290065312940752 + 0.3700633254092476im
    -0.8941821515971767 + 0.44770333901484094im
    -0.8540435282802706 + 0.5202015492120222im
    -0.8089368000798132 + 0.5878956144390027im
    -0.7590696675279228 + 0.6510094007301724im
    -0.7045520967014851 + 0.7096522690963082im
    -0.6454298080537827 + 0.7638195879104205im
    -0.5817128876744944 + 0.8133941949100721im
    -0.5134021893499194 + 0.8581481177341772im
    -0.4405148544945159 + 0.8977453218868214im
    -0.36310981031439205 + 0.931746352637589im
    -0.2813143569621175 + 0.9596156691962641im
    -0.19535143016731743 + 0.9807333066290598im
    -0.10556734149622815 + 0.9944121562055724im
    -0.012458524000260929 + 0.9999223895781908im
    0.08330454696041856 + 0.9965241354105387im
    0.18085919049349397 + 0.983509000067632im
    0.27914141567319917 + 0.9602500039343675im
    0.37688972006924204 + 0.9262581383751131im
    0.4726651941037465 + 0.8812420860824055im
    0.564890492365139 + 0.8251658812841747im
    0.6519081984978072 + 0.7582978970901302im
    0.7320565714498721 + 0.6812438448874626im
    0.8037574664104166 + 0.5949570868470395im
    0.8656084368052646 + 0.5007215135497207im
    0.9164690193889522 + 0.4001056566711438im
    0.9555309637060181 + 0.2948907889356334im
    0.9823637382530186 + 0.18697990738458733im
    0.9969300422199954 + 0.07829745155001885im
    0.9995703964433589 - 0.029309086544006664im
    0.9909603079155094 - 0.1341553880244837im
    0.9720469407335981 - 0.23478659461400742im
    0.9439741029997029 - 0.330019534067174im
    0.9080044977917552 - 0.41896041816612245im
];

p1 = [
    0.007182694121606963,
    0.015472913310680137,
    0.023613486560982708,
    0.03176519662631298,
    0.04003770156900387,
    0.04814603562287013,
    0.056427748813364265,
    0.06475689342570697,
    0.07290854337261643,
    0.081047170651266,
    0.08931966724027199,
    0.09754746730603815,
    0.10583726744553563,
    0.11407638809600433,
    0.12225467971016615,
    0.13048764582595057,
    0.1386656171150682,
    0.14686257666235852,
    0.15478821133930734,
    0.16291614465114201,
]


freqs = genFreqs(22.025e9,50e6; length=length(ref1))
freqsplot = genFreqs(22.025e9,150e6; length=1000)


n = 20
d0 = findpeak(22.025e9,n)
p0 = dist2pos(ones(n)*d0);

b = AnalyticalBooster(d0); b.tand = 0.;


move(b,p0)

hist = initHist(b,10000,freqs,ObjRefSquare(ref1));

trace = nelderMead(b,hist,freqs,
    1.,1+2/n,0.75-1/2n,1-1/n,1e-6,
    ObjRefSquare(ref1),
    InitSimplexCoord(100e-6),
    DefaultSimplexSampler,
    UnstuckDont;
    maxiter=1000,
    showtrace=true,
    showevery=50,
    unstuckisiter=true,
    resettimer=true); 0
;

p = analyse_(hist,trace,freqsplot; freqs=freqs)


savefig(p[1],"NM_20_ref_boost.pdf")
savefig(p[2],"NM_20_ref_trace.pdf")
savefig(p[3],"NM_20_ref_trace_dist.pdf")
savefig(p[5],"NM_20_ref_hist.pdf")
savefig(p[6],"NM_20_ref_hist_dist.pdf")




s = scatter(1:n, pos2dist(p1)/1e-3; label="reference",c=:blue)
scatter!(1:n, pos2dist(b.pos)/1e-3; label="optimized",c=:red)
xlabel!("Disc")
ylabel!("Distances "*L"d_i"*" [mm]")
# ylims!()

savefig("20discoptrefdistances.pdf")




reff = getRef1d(b,freqs)

plot(freqs/1e9,real.(ref1); c=:blue,label="reference")
plot!(freqs/1e9,imag.(ref1); c=:blue,linestyle=:dash,label="")

plot!(freqs/1e9,real.(reff); c=:red,label="optimized")
plot!(freqs/1e9,imag.(reff); c=:red,linestyle=:dash,label="")
xlabel!("Frequency [GHz]")
ylabel!("Reflectivity "*L"R")

savefig("20discoptref.pdf")

function analyse_(hist, trace::Vector{NMTrace}, freqsplot;
        freqs=nothing,
        plotting=true,
        div=5,
        scale=1e9,
        ylim=[-0.05e4, 3e4],
        freqticks=[21.95,22.0,22.05,22.1])

    tracex = hcat((x -> x.x[:, 1]).(trace)...)
    tracex_ = hcat((x -> x.x_).(trace)...)
    traced = hcat((x -> pos2dist(x.x[:, 1])).(trace)...)
    traced_ = hcat((x -> pos2dist(x.x_)).(trace)...)
    tracef = (x -> x.obj[1]).(trace)
    tracef_ = (x -> x.obj_).(trace)

    l = length(trace)
    n = length(tracex[:, 1])

    lh = length(hist[(x->x.objvalue).(hist).!=0.0])

    histx = hcat((x -> x.pos).(hist[lh:-1:1])...)
    histf = (x -> x.objvalue).(hist[lh:-1:1])
    histd = hcat((x -> pos2dist(x.pos)).(hist[lh:-1:1])...)

    if plotting
        plt1 = plot(freqsplot / scale, boost1d(pos2dist(tracex[:, 1]), freqsplot)/1e3;
            ylim=ylim/1e3, label="init", lc="blue", lw=2)

        if div != 0
            for i in 2:maximum([1, l ÷ div]):(l-1)
                plot!(freqsplot / scale, boost1d(pos2dist(tracex[:, i]), freqsplot)/1e3;
                    ylim=ylim/1e3, label="it.: " * string(i))
            end
        end

        plot!(freqsplot / scale, boost1d(pos2dist(tracex[:, l]), freqsplot)/1e3;
            ylim=ylim/1e3, label="final", lc="red", lw=2)

        if !isnothing(freqs)
            vline!([minimum(freqs), maximum(freqs)] / scale, c="black", linestyle=:dash,
                label="")
        end
        # title!("Boostfactor")
        xticks!(freqticks)
        xlabel!("Frequency [GHz]")
        ylabel!("Power Boost Factor "*L"\beta^2")
        annotate!([(minimum(freqsplot) / scale, 0.9 * ylim[2]/1e3,
            L"f_{\beta,F}:" * string(round(-13751.0203, digits=0)), :left)])
        annotate!((minimum(freqsplot)+-(extrema(freqsplot)...)*0.1) / scale,
            -0.05*ylim[2]/1e3,(L"\times 10^3",10,:left))

        plt2 = plot(1:l, tracef; legend=false)
        # title!("Objective trace best vertex")
        xlabel!("Iteration")
        ylabel!("Objective Value "*L"f_{R}")
        annotate!(-0.1*length(tracef),-(extrema(tracef)...)*0.95,
            (L"\times 10^3",10,:left))

        plt3 = plot(1:l, traced'/1e-3; legend=false)
        # title!("Distance trace best vertex")
        xlabel!("Iteration")
        ylabel!("Distances "*L"d_i"*" [mm]")

        plt4 = scatter(1:n, traced[:, l]/1e-3; legend=false)
        # title!("Final distances")
        xlabel!("Disk")
        ylabel!("Distances "*L"d_i"*" [mm]")

        plt5 = plot(1:lh, histf[1:lh]; legend=false)
        # title!("History objective value")
        xlabel!("Step")
        ylabel!("Objective Value "*L"f_{R}")
        annotate!(-0.1*length(histf[1:lh]),-(extrema(histf[1:lh])...)*0.95,
            (L"\times 10^3",10,:left))

        plt6 = plot(1:lh, histd[:, 1:lh]'/1e-3; legend=false)
        # title!("History distances")
        xlabel!("Step")
        ylabel!("Distances "*L"d_i"*" [mm]")

        display(plt1)
        display(plt2)
        display(plt3)
        display(plt4)
        display(plt5)
        display(plt6)
    end

    if !plotting
        return tracex, tracex_, traced, traced_, tracef, tracef_,
        histx, histf, histd
    else
        return plt1, plt2, plt3, plt4, plt5, plt6
    end
end

