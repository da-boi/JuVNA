using Pkg

Pkg.add(url="https://github.com/bergermann/Dragoon.jl.git")
Pkg.update()

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

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

closeDevice(D[2],D[3],D[4])
D = D[1:1]

getPosition(D,stagecals)



# =========================================================================

vna = connectVNA()
setPowerLevel(vna,9)
setAveraging(vna,false)
setFrequencies(vna,20.00e9,3e9)
setSweepPoints(vna,128)
setIFBandwidth(vna,Int(100e6))
# setFormat2Log(vna)
setCalibration(vna,"{483B25B2-6FE9-483E-8A93-0527B8D277E2}")
# instrumentSimplifiedSetup(vna)

freqs = collect(Float64,getFreqAsBinBlockTransfer(vna))

# check vna setup


function objRefVNA(booster::Booster,freqs::Vector{Float64},(vna,ref0)::Tuple{TCPSocket,Vector{ComplexF64}})
    ref = getTrace(vna)

    return sum(abs.(ref-ref0))
end

function objRefRef(booster::Booster,freqs::Vector{Float64},(ref,ref0)::Tuple{Vector{ComplexF64},Vector{ComplexF64}})
    return sum(abs.(ref-ref0))
end

ObjRefVNA(vna,ref0) = Callback(objRefVNA,(vna,ref0))
ObjRefRef(ref,ref0) = Callback(objRefRef,(ref,ref0))

# =========================================================================



# freqs = genFreqs(22.025e9,50e6; length=10);
# freqsplot = genFreqs(22.025e9,150e6; length=1000);
freqsplot = genFreqs(20.0e9,3e9; length=12800)

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices, τ=0.,ϵ=1.,maxlength=0.2);

homeZero(b)
# move(b,[0.01]; additive=true)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)


steps = 500

hist = initHist(b,steps+1,freqs,objFR(ref0));
updateHist!(b,hist,freqs,objFR(ref0))
R = zeros(ComplexF64,steps,length(ref0))


# homeZero(b)
# ref0 = getTrace(vna)
for i in 1:steps
    (i%10 == 0) && println("step: ",i)

    move(b,[0.0001]; additive=true)

    ref = getTrace(vna)
    updateHist!(b,hist,freqs,objFR(ref))
    R[i,:] = ref
end

plot(reverse((x->x.objvalue).(hist)))



# =======================================================================


homeZero(b)
move(b,[0.025]; additive=true)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)


steps = 500

hist = initHist(b,steps+1,freqs,objFR(ref0));
updateHist!(b,hist,freqs,objFR(ref0))
R = zeros(ComplexF64,steps,length(ref0))


homeZero(b)
# ref0 = getTrace(vna)
for i in 1:steps
    (i%10 == 0) && println("step: ",i)

    move(b,[0.0001]; additive=true)

    ref = getTrace(vna)
    updateHist!(b,hist,freqs,objFR(ref))
    R[i,:] = ref
end

plot(reverse((x->x.objvalue).(hist)))



## ==================================================================


devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices, τ=0.,ϵ=1.,maxlength=0.2);

homeZero(b)
move(b,[0.05]; additive=false)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)



move(b,[0.005]; additive=true)
hist = initHist(b,1001,freqs,objF);

trace = nelderMead(b,hist,freqs,
                1.,1+2/b.ndisk,
                0.75-1/(2*b.ndisk),1-1/(b.ndisk),
                objF,
                InitSimplexCoord(0.005),
                DefaultSimplexSampler,
                UnstuckDont;
                maxiter=Int(1e1),
                showtrace=true,
                showevery=1,
                unstuckisiter=true);

plot(reverse((x->x.objvalue).(hist)))

analyse(hist,trace,freqs)



## ==================================================================



plot(real.(ref0))
plot!(imag.(ref0))

ref = getTrace(vna)
plot(real.(ref))
plot!(imag.(ref))

