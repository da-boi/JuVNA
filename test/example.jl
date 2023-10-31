include("../src/scan.jl")
using .Scan

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

data = scan(usteps=10, file="data.jld2", setup="test/vna_settings.txt", motor="Alexanderson")