# for testing purposes only

using Dragoon
using DataStructures

include("vna_control.jl")
#include("stages.jl")
include("JuXIMC.jl")
include("dataIO.jl")

stagenames = Dict{String, Int}("Big Chungus" => 1, "Monica" => 2, "Alexanderson" => 3, "Bigger Chungus" => 4,)
stagecals  = Dict{String, Tuple{Symbol,Int}}("Big Chungus" => (:mm,80), "Monica" => (:mm,800), "Alexanderson" => (:mm,800), "Bigger Chungus" => (:mm,80))

JuXIMC.infoXIMC()

JuXIMC.setBindyKey(
    joinpath(
        dirname(@__DIR__),
        "XIMC\\ximc-2.13.6\\ximc\\win64\\keyfile.sqlite"
    )
)

devcount, devenum, enumnames = JuXIMC.setupDevices(JuXIMC.ENUMERATE_PROBE | JuXIMC.ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = JuXIMC.openDevices(enumnames,stagenames)
JuXIMC.checkOrdering(D,stagenames)
# JuXIMC.closeDevice(D[1:3])
# D = D[4]

#JuXIMC.commandMove(D,[20,20,20],stagecals)
#JuXIMC.commandMove(D,zeros(3),stagecals)

f_center::Float64 = 19e9
f_span::Float64 = 3e9
sweeppoints::Int = 16384
#sweeppoints::Int = 5001

vna = connectVNA()
instrumentSimplifiedSetup(vna, "{AAE0FD65-EEA1-4D1A-95EE-06B3FFCB32B7}", -20, f_center, f_span, sweeppoints, 50000)
getDataAsBinBlockTransfer(vna)

data = Vector{Vector{Float64}}(undef, 0)
pos_data = Vector{JuXIMC.Position}(undef, 0)

f_data = getFreqAsBinBlockTransfer(vna)

posStart = JuXIMC.Position(28000, 0)
posEnd = JuXIMC.Position(25000, 0)

stepSize = 250
steps = Int(abs((posEnd.Position-posStart.Position) / stepSize ))
pos_points = [posEnd.Position + i*250 for i in 1:steps]
posStack = Stack{JuXIMC.Position}()
for x in pos_points
    push!(posStack, JuXIMC.Position(x, 0))
end
posNext = JuXIMC.Position()
posNext = pop!(posStack)

JuXIMC.commandMove(D[4], posStart)
JuXIMC.command_wait_for_stop(D[4], 0x00000a)
JuXIMC.commandMove(D[4], posEnd)

while true
    pos = JuXIMC.getPosition(D[4])
    if JuXIMC.isGreaterEqPosition(posNext, pos)
        println(pos.Position, " ", pos.uPosition, "'")
        push!(pos_data, pos)
        push!(data,getDataAsBinBlockTransfer(vna))
        posNext = pop!(posStack)
    end
    if JuXIMC.isGreaterEqPosition(posEnd, pos) break end
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