module Scan

include("JuXIMC.jl")
include("JuVNA.jl")

import .VNA
using JLD2, Sockets

export scan, getCurrentPosition, setMicroStepMode

function scan(;
    stepSize=100.0,
    steps=0,
    file="",
    setup="test/vna_20G_3G.txt",
    motor="Big Chungus"
    )

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
    S, deltaX = _scan(vna, D[1]; stepSize=stepSize, steps=steps)

    # Disconnect from motor
    closeDevices(D)

    if file != ""
        @save "data.jld2" S freq deltaX
    end


    # Disconnect from VNA
    VNA.disconnect(vna)

    return (S, freq, deltaX)
end

# Scans the given range
# Performing a sweep at each position
function _scan(
    socket::Sockets.TCPSocket,
    D::DeviceId;
    stepSize=100.0,
    steps::Integer=0
    )

    data = []
    deltaX = 0

    for i in 0..steps
        # Move and wait until position is reached
        deltaX = commandMoveRelative(D, stepSize)
        commandWaitForStop(D)

        # Perform the sweep
        push!(data, VNA.getTrace(socket))

        println("Step $(0) \t Position (um) = $(i*deltaX)")
    end

    return (data, deltaX)
end

end