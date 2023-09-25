using Dragoon
using LaTeXStrings

init

freqs = genFreqs((22.0e9,22.045e9); length=101)

b0 = boost1d(init,freqs)


A = 0.99:0.0001:1.01

B = Vector{Float64}([])
for a in A
    push!(B,-minimum(boost1d(a.*init,freqs)))
end

plot(A,B)



d0 = findpeak(22.025,20)
d = ones(20)*d0

A = 0.99:0.0001:1.01

B = Vector{Float64}([])
for a in A
    push!(B,-minimum(boost1d(a.*d,freqs)))
end

plot(A,B)


d1 = pos2dist([
    0.0071104117354328965,
    0.015515178080012373,
    0.02361755347957437,
    0.03178905016495553,
    0.03991324064999641,
    0.048174950743456825,
    0.056452613907255374,
    0.06468189274041375,
    0.07295034336322337,
    0.08115771999132358,
    0.08933086614454841,
    0.09757745861651922,
    0.10579819744583897,
    0.11407911100903867,
    0.12228173993056626,
    0.1305483332032982,
    0.13865692815607195,
    0.14683160045399876,
    0.1548182784390491,
    0.16293102979758506,
])

d2 = pos2dist([
    0.007247735971065718,
    0.0153536059801698,
    0.02349362482860758,
    0.031725725101436765,
    0.04008360063487755,
    0.04825499586047874,
    0.056374071955164216,
    0.06465167235674646,
    0.07290613551219695,
    0.08109457086693071,
    0.08921112321349785,
    0.09773128357821437,
    0.10577817561583536,
    0.11401211688831774,
    0.12224161990470536,
    0.13068863948122553,
    0.13873058422193918,
    0.14693888933980132,
    0.1548545450769799,
    0.16304131758897814,
])

freqs = genFreqs(22.025e9,50e6; length=101)
b0 = boost1d(d1,freqs)



dd = d2 - d1

A = -0.1:0.001:1.1
B = Vector{Float64}([])

for a in A
    push!(B,-minimum(boost1d(d1+a*dd,freqs)))
end


p2 = plot(A,B/1e3; legend=false)
xlabel!(L"\alpha")
ylabel!("Objective Value "*L"f_{\beta}(\alpha)")
annotate!(-0.22,-15,(L"\times 10^3",10,:left))

freqsplot = genFreqs(22.025e9,150e6; length=1001)

p1 = plot(freqsplot/1e9,boost1d(d1,freqsplot)/1e3; label="Solution A",c=:blue,layout=grid(2,1,heights=[0.8,0.2]),subplot=1)
plot!(p1[1],freqsplot/1e9,boost1d(d2,freqsplot)/1e3; label="Solution B",c=:red,subplot=1)
annotate!(p1[1],(minimum(freqsplot)+-(extrema(freqsplot)...)*0.1)/1e9,
            -2000/1e3,(L"\times 10^3",10,:left))
xlabel!(p1[1],"Frequency [GHz]")
ylabel!(p1[1],"Power Boost Factor "*L"\beta^2")
vline!(p1[1],[22,22.05], c="black", linestyle=:dash,label="")
xticks!([21.95,22.0,22.05,22.1])



scatter!(p1[2],1:20,d1*1e3; label="Solution A",c=:blue,subplot=2,ylims=[6.8,7.6],legend=false)
scatter!(p1[2],1:20,d2*1e3; label="Solution B",c=:red,subplot=2,legend=false)
xlabel!(p1[2],"Disc index",subplot=2)
ylabel!(p1[2],L"d_i"*" [mm]",subplot=2)


savefig(p1,"convex1.pdf")
savefig(p2,"convex2.pdf")