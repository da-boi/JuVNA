import Dates
using FileIO

include("../src/ctypes.jl")
include("../src/jtypes.jl")

struct VNAParameters
    calName::String
    power::Integer
    center::Float64
    span::Float64
    ifbandwidth::Integer
    sweepPoints::Integer
    sweepTime::Float64
    fastSweep::Bool
end

struct Measurement
    label::String
    param::VNAParameters
    freq::Vector{Float64}
    data::Matrix{ComplexF64}
    pos::Vector{Position}
    posSet::Vector{Integer}
end

function readMeasurementOld(filename::String)::Measurement
    Serialization.deserialize(filename)
end

function saveMeasurement(data; filename::String="", name::String="unnamed", filedate=true)
    if filename == ""
        if filedate date = Dates.format(Dates.now(), "yyyy-mm-dd_") else date = "" end
        i = 1
        while true
            filename = name * "_" * date * string(i) * ".jld2"
            if !isfile(filename) break end
            i += 1
        end
    end

    @save filename data

    return
end

function readMeasurement(filename::String)
    @load filename data

    return data
end