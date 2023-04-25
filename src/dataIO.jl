
import JSON

struct VnaParameters
    calName::String
    power::Int
    center::Float64
    span::Float64
    sweeppoints::Int
    ifbandwidth::Int
end

struct Measurement
    param::VnaParameters
    freq::Vector{Float64}
    data::Matrix{Float64}
end

function saveMeasurement(data::Measurement, file::String)
    stringdata = JSON.json(data, 4)

    # write the file with the stringdata variable information
    open(file, "w") do f
        write(f, stringdata)
    end
end