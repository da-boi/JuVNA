include("../src/JuVNA.jl")

import .VNA

# Connect to the VNA
vna = VNA.connect()

# Load settings from a file
VNA.setupFromFile(vna, "vna_20G_3G.txt")

# Perform a single trace
# Returns the scattering parameter S11 for each frequency point as a
# Vector{ComplexF64}
data = VNA.getTrace(vna)

# Returns the frequency points
freq = VNA.getFrequencies(vna)