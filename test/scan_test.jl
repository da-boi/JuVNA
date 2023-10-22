include("../src/JuXIMC.jl")
include("../src/JuVNA.jl")

import .VNA
using JLD2, FileIO


# Connect to the motor
infoXIMC();
D = requestDevices("Big Chungus")

# Connect to the VNA
vna = VNA.connect()
VNA.setupFromFile(vna, "vna_20G_3G.txt")

# Reading the current position of the motor
pos = getPosition(D)
println("current motor position: $(pos)")

# Measuring the range
# And saving the S parameter and positions
# Where
#   S       is a Vector{Vector{ComplexF64}} (first position, second frequency)
#   pos     is a Vector{Int} (given in steps, 1 step = 12.5 um)
#   freq    is a Vector{Int}
freq = VNA.getFrequencies(vna)
S, pos = scan(vna, D, 0, 1000; stepSize=100)
@save "data.jld2" S, pos, freq




### Functions ###

# Scans the given range
# Performing a sweep at each position
function scan(socket::Sockets.TCPSocket, D::DeviceID, startPos::Integer, endPos::Integer; stepSize::Integer=250)
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