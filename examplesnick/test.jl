# for testing purposes only

using Dragoon
using DataStructures

include("../src/vna_control.jl")
include("../examplesdom/stages.jl")
include("../src/JuXIMC.jl")
include("dataIO.jl")

infoXIMC()

devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
#   closeDevice(D[1:3])
# D = D[4]

#commandMove(D,[20,20,20],stagecals)
#commandMove(D,zeros(3),stagecals)

f_center::Float64 = 19e9
f_span::Float64 = 3e9
#sweeppoints::Int = 16384
sweeppoints::Int = 1024

vna = connectVNA()
instrumentSimplifiedSetup(vna, calName="{AAE0FD65-EEA1-4D1A-95EE-06B3FFCB32B7}"; power=-20, center=f_center, span=f_span, sweeppoints=sweeppoints, ifbandwidth=100000, measurement="CH1_S11_1")
getDataAsBinBlockTransfer(vna)

data = Vector{Vector{Float64}}(undef, 0)
pos_data = Vector{Position}(undef, 0)

f_data = getFreqAsBinBlockTransfer(vna)

posStart = Position(28000, 0)
posEnd = Position(25000, 0)

stepSize = 250
steps = Int(abs((posEnd.Position-posStart.Position) / stepSize ))
pos_points = [posEnd.Position + i*250 for i in 1:steps]
posStack = Stack{Position}()
for x in pos_points
    push!(posStack, Position(x, 0))
end
posNext = Position()
posNext = pop!(posStack)

commandMove(D[4], posStart)
command_wait_for_stop(D[4], 0x00000a)
commandMove(D[4], posEnd)

while true
    pos = getPosition(D[4])
    if isGreaterEqPosition(posNext, pos)
        println(pos.Position, " ", pos.uPosition, "'")
        push!(pos_data, pos)
        push!(data,getDataAsBinBlockTransfer(vna))
        posNext = pop!(posStack)
    end
    if isGreaterEqPosition(posEnd, pos) break end
end

data = Matrix(reduce(hcat, data))
param = VnaParameters("{AAE0FD65-EEA1-4D1A-95EE-06B3FFCB32B7}", -20, f_center, f_span, sweeppoints, 50000)
meas = Measurement(param, f_data, data)
saveMeasurement(meas, "measurement.json")


#=
function calcFieldProportionality(S_perturbed::Float64, S_unperturbed::Float64, frequency::Float64)
    return Float64(sqrt(abs( (S_perturbed - S_unperturbed) / frequency / 6.28 )))
end

function calcFieldProportionality(S_perturbed::Vector{Float64}, S_unperturbed::Vector{Float64}, frequency::Vector{Float64})::Vector{Float64}
    ret = Float64[]

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i], S_unperturbed[i], frequency[i]))
    end

    return ret
end
=#