module Scan

include("JuXIMC.jl")
include("JuVNA.jl")

import .VNA
using JLD2, Sockets

export scan, getCurrentPosition

function getCurrentPosition(;motor="Big Chungus")
    # Connect to the motor
    D = requestDevices(motor)

    # Reading the current position of the motor
    pos = getPosition(D)
    println("current motor position: $(pos)")

    # Disconnect from motor
    closeDevices(D)

    return pos
end

function scan(startPos::Integer, endPos::Integer; stepSize=100, file="", setup="test/vna_20G_3G.txt", motor="Big Chungus")

    # Connect to the motor
    infoXIMC();
    D = requestDevices(motor)

    # Connect to the VNA
    vna = VNA.connect()
    VNA.setupFromFile(vna, setup)

    # Measuring the S-parameter
    # Where
    #   S       is a Vector{Vector{ComplexF64}} (first position, second frequency)
    #   pos     is a Vector{Int} (given in steps, 1 step = 12.5 um)
    #   freq    is a Vector{Int}
    freq = VNA.getFrequencies(vna)
    S, pos = _scan(vna, D[1], startPos, endPos; stepSize=1000)

    # Disconnect from motor
    closeDevices(D)

    if file != ""
        @save "data.jld2" S pos freq
    end


    # Disconnect from VNA
    VNA.disconnect(vna)

    return (S, pos, freq)
end


### Functions ###

# Scans the given range
# Performing a sweep at each position
function _scan(socket::Sockets.TCPSocket, D::DeviceId, startPos::Integer, endPos::Integer; stepSize::Integer=250)
    posSet = getMeasurementPositions(startPos, endPos; stepSize=stepSize)
    data = []

    for p in posSet
        # Move and wait until position is reached
        commandMove(D, p, 0)
        commandWaitForStop(D)

        # Perform the sweep
        push!(data, VNA.getTrace(socket))
    end

    return (data, posSet)
end

# Creates the set of positions, where to perform a measurement
function getMeasurementPositions(startPos::Integer, endPos::Integer; stepSize::Integer=250)
    if startPos <= endPos
        return Vector{Integer}(startPos:stepSize:endPos)
    else
        return reverse(Vector{Integer}(endPos:stepSize:startPos))
    end
end

end