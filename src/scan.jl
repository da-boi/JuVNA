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


### scan()
# The function measures the scattering parameter using the VNA for a specified
# number of usteps. Note, that for usteps=0 the function returns one position.
# The initial one, without moving.
#
## Arguments:
# usteps: The amount of micro steps to go
#
# file: The filename, where to save the data
#       if none is given, the data is not saved
#       Note: The data is saved in the JLD2 format, which is a Julia
#             implementation of the HDF5 format
#
# setup: The settings file for the VNA
#        if none is given, the current VNA settings are not changed
#
# motor: The name of the motor to be used
#
## Return:
# Returns a tuple (S, freq)
# S: is the scattering parameter as a Vector{Vector{ComplexF64}}
#    where the first index is over the usteps
#    and the second over the frequencies
#
# freq: are the frequencies as a Vector{Float}
function scan(;
    stepSize=1,
    usteps=0,
    file="",
    setup="",
    motor="Big Chungus"
    )

    # Connect to the motor
    infoXIMC();
    D = requestDevices(motor)[1]

    # Connect to the VNA
    vna = VNA.connect()
    VNA.setupFromFile(vna, setup)

    # Measuring the S-parameter
    # Where
    #   S       is a Vector{Vector{ComplexF64}} (first position, second frequency)
    #   freq    is a Vector{Int}
    freq = VNA.getFrequencies(vna)
    S = _scan(vna, D; stepSize=stepSize, steps=usteps)

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

    push!(data, VNA.getTrace(socket))

    for i in 1:stepSize:steps
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