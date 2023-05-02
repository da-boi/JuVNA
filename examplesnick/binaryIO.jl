import Dates
import Serialization

include("../src/JuXIMC.jl")
include("../src/vna_control.jl")

struct Measurement
    param::VNAParameters
    freq::Vector{Float64}
    #pos::Vector{Position}
    #posSet::Vector{Position}
    data::Matrix{ComplexF64}
end

# Saves a Measurement struct in a binary file
# if [filename] is specified, the data is saved in this file
# otherwise the date is saved in "[dir]/[name] yyyy-mm-dd HH:MM:SS.data"
# with the current date and time
function saveMeasurement(data::Measurement; filename::String="", name::String="unnamed", dir::String="")
    if filename == ""
        date = Dates.format(Dates.now(), "yyyy-mm-dd HH:MM:SS")
        filename = dir * "/" * name * " " * date * ".data"
    end

    file = open(filename, "w")
    Serialization.serialize(file, data)
    close(file)
end

# Reads a Measurement struct from a binary file
# correct data format is assumed => be cautious to only open trusted files
function readMeasurement(filename::String)::Measurement
    Serialization.deserialize(filename)
end