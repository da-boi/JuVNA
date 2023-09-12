using Dragoon
using Dates
using Plots
using JLD2
using LaTeXStrings
using Statistics


include(joinpath(pwd(),"src/vna_control.jl"));
include(joinpath(pwd(),"src/JuXIMC.jl"));
include(joinpath(pwd(),"examplesdom/dragoonstuff.jl"));

include("stages2discs_c.jl");

# ======================================================================================================================

vna = connectVNA();

# setSweepPoints(vna,128)

freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    # sleep(2)

    ref = getTrace(vna)

    return sum(abs.(ref-ref0))
end

function objRefRef(booster::Booster,freqs::Vector{Float64},(ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})
    return sum(abs.(ref-ref0))
end

ObjRefVNA(vna,ref0) = Callback(objRefVNA,(vna,ref0))
ObjRefRef(ref,ref0) = Callback(objRefRef,(ref,ref0));

# ======================================================================================================================

infoXIMC();

D = requestDevices("Motor 7","Monica");

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders,stagehomes);
b = PhysicalBooster(devices; τ=1e-3,ϵ=9.4,maxlength=0.2);

# homeHome(b)

p0 = [0.013,0.027]
move(b,p0; additive=false); getTrace(vna);

# ======================================================================================================================
# noise empty power

# Rnoiseemptym20 = zeros(nm)

move(b,p0; additive=false)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

move(b,[0.0,0.001]; additive=true)

nm = 1000



setPowerLevel(vna,-20)

objnoiseemptym20 = zeros(nm)

@time for i in 1:nm
    sleep(0.1)
    objnoiseemptym20[i] = objRefVNA(b,freqs,(vna,ref0))
end



setPowerLevel(vna,-30)

objnoiseemptym30 = zeros(nm)

@time for i in 1:nm
    sleep(0.1)
    objnoiseemptym30[i] = objRefVNA(b,freqs,(vna,ref0))
end



setPowerLevel(vna,-40)

objnoiseemptym40 = zeros(nm)

for i in 1:nm
    sleep(0.1)
    objnoiseemptym40[i] = objRefVNA(b,freqs,(vna,ref0))
end



setPowerLevel(vna,-50)

objnoiseemptym50 = zeros(nm)

for i in 1:nm
    sleep(0.1)
    objnoiseemptym50[i] = objRefVNA(b,freqs,(vna,ref0))
end



setPowerLevel(vna,-60)

objnoiseemptym60 = zeros(nm)

for i in 1:nm
    sleep(0.1)
    objnoiseemptym60[i] = objRefVNA(b,freqs,(vna,ref0))
end



setPowerLevel(vna,-10)

objnoiseemptym10 = zeros(nm)

for i in 1:nm
    sleep(0.1)
    objnoiseemptym10[i] = objRefVNA(b,freqs,(vna,ref0))
end

R1 = []

@time for i in 1:100
    push!(R1,getTrace(vna))
end

R2 = []

@time for i in 1:100
    push!(R2,getTrace(vna))
end

R3 = []

@time for i in 1:100
    push!(R3,getTrace(vna))
end

using BenchmarkTools

@btime getTrace(vna);





setPowerLevel(vna,0)

objnoiseemptym0 = zeros(nm)

for i in 1:nm
    sleep(0.1)
    objnoiseemptym0[i] = objRefVNA(b,freqs,(vna,ref0))
end

sigma = std.([objnoiseemptym0,objnoiseemptym10,objnoiseemptym20,objnoiseemptym30,objnoiseemptym40,objnoiseemptym50,objnoiseemptym60])

histogram(objnoiseempty)



# ======================================================================================================================
### optimization linesearch steepest


move(b,p0; additive=false)

move(b,[0.0,0.001]; additive=true)


move(b,p0; additive=false)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histtest = initHist(b,50,freqs,objFR(ref0))
updateHist!(b,histtest,freqs,objFR(ref0))

move(b,[0.0,0.001]; additive=true)

derivator_ = Derivator2(10e-6,10e-6,"double")

g_ = zeros(b.ndisk)
h_ = zeros(b.ndisk,b.ndisk)

move(b,p0+[0.0,0.001]; additive=false)

derivator_.func(g_,h_,b,histtest,freqs,objF,derivator_.args); display(g_); display(h_)



p_ = -inv(h_)*g_






move(b,p0; additive=false)

ref0 = getTraceG(vna,10)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)

histtest = initHist(b,50,freqs,objFR(ref0))
updateHist!(b,histtest,freqs,objFR(ref0))

derivator_ = Derivator2(100e-6,100e-6,"double")

g_ = zeros(b.ndisk)
h_ = zeros(b.ndisk,b.ndisk)

move(b,p0+[0.0,0.001]; additive=false)
p1=copy(b.pos)

derivator_.func(g_,h_,b,histtest,freqs,objF,derivator_.args); display(g_); display(h_); display(b.pos-p1)

p_ = -inv(h_)*g_


move(b,[10e-6,0]; additive=true)

r2 = zeros(100)

for i in 1:100
    r2[i] = objRefVNA(b,freqs,(vna,ref0))
end