module Scan

include("JuXIMC.jl")
include("JuVNA.jl")

import .VNA
using JLD2, Sockets

export scan, getCurrentPosition, setMicroStepMode,
    MICROSTEP_MODE_FULL,
	MICROSTEP_MODE_FRAC_2,
	MICROSTEP_MODE_FRAC_4,
	MICROSTEP_MODE_FRAC_8,
	MICROSTEP_MODE_FRAC_16,
	MICROSTEP_MODE_FRAC_32,
	MICROSTEP_MODE_FRAC_64,
	MICROSTEP_MODE_FRAC_128,
	MICROSTEP_MODE_FRAC_256

function scan(;
    stepSize=1,
    steps=0,
    file="",
    setup="test/vna_20G_3G.txt",
    motor="Big Chungus",
    microstep=0
    )

    # Connect to the motor
    infoXIMC();
    D = requestDevices(motor)[1]

    if microstep != 0
        setMicroStepMode(D, mode=microstep)
    end

    # Connect to the VNA
    vna = VNA.connect()
    VNA.setupFromFile(vna, setup)

    # Measuring the S-parameter
    # Where
    #   S       is a Vector{Vector{ComplexF64}} (first position, second frequency)
    #   pos     is a Vector{Int} (given in steps, 1 step = 12.5 um)
    #   freq    is a Vector{Int}
    freq = VNA.getFrequencies(vna)
    S= _scan(vna, D; stepSize=stepSize, steps=steps)

    # Disconnect from motor
    closeDevices(D)

    if file != ""
        @save "data.jld2" S freq
    end


    # Disconnect from VNA
    VNA.disconnect(vna)

    return (S, freq)
end

# Scans the given range
# Performing a sweep at each position
function _scan(
    socket::Sockets.TCPSocket,
    D::DeviceId;
    stepSize=1,
    steps::Integer=0
    )

    data = []

    engine = getEngineSettings(D)
    microsteps = 2 ^ (engine.MicrostepMode - 1)

    println("Microstep Mode: 1/$(microsteps)")
    println("Scanning...")
    println("Step ")

    for i in 0:stepSize:steps
        # Move and wait until position is reached
        commandMoveRelative(D, 0, 1)
        print("$(i) ")
        commandWaitForStop(D)
        

        # Perform the sweep
        push!(data, VNA.getTrace(socket))
    end

    return data
end

end