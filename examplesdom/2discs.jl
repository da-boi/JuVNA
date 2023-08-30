using Dragoon
using Dates
using Plots
using JLD2


include("../src/vna_control.jl");
include("../src/JuXIMC.jl");
include("../examplesdom/dragoonstuff.jl");

include("../examplesdom/stages 3discs.jl");

infoXIMC();

D = requestDevices("Monica","Alexanderson")

commandMove(D,Matrix{Int32}([0 0; 0 0]); info=true)

getPosition(D,stagecals)

# =========================================================================

vna = connectVNA()
setupFromFile(vna,"src/vna_20G_3G.txt")

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

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices, τ=1e-3,ϵ=9.1,maxlength=0.2);

# =========================================================================

homeZero(b)
move(b,[0.025,0.025]; additive=true)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)


steps = 10

hist = initHist(b,(2*steps+1)^2+1,freqs,objFR(ref0));
updateHist!(b,hist,freqs,objFR(ref0))
R = zeros(ComplexF64,2*steps+1,2*steps+1,length(ref0))

p0 = copy(b.pos)

@time for i in -steps:steps, j in -steps:steps
    j == -steps && println("i: ",i)
    move(b,p0+[i*0.001,j*0.001]; additive=false)
    
    ref = getTrace(vna)
    updateHist!(b,hist,freqs,objFR(ref))
    R[i+steps+1,j+steps+1,:] = ref
end

@save "2_discs_scan_ref_and_hist_middle.jld2" ref0 hist R freqs



# =========================================================================

homeZero(b)
move(b,[0.025,0.025]; additive=true)

ref0 = getTrace(vna)
objF = ObjRefVNA(vna,ref0)
objFR(ref) = ObjRefRef(ref,ref0)



hist = initHist(b,1001,freqs,objFR(ref0));
updateHist!(b,hist,freqs,objFR(ref0))



move(b,[0.0,0.001]; additive=true)

trace = nelderMead(b,hist,freqs,
                1.,1+2/b.ndisk,
                0.75-1/(2*b.ndisk),1-1/(b.ndisk),
                objF,
                InitSimplexCoord(0.001),
                DefaultSimplexSampler,
                UnstuckDont;
                maxiter=50,
                showtrace=true,
                showevery=1,
                unstuckisiter=true,
                resettimer=true);

plot(reverse((x->x.objvalue).(hist)))
# plotRef(ref0; freqs=freqs)
plotRef(getTrace(vna); freqs=freqs)

analyse(hist,trace,freqs)

@save "2_disc_opt_trace_hist_middle.jld2" ref0 trace hist freqs
