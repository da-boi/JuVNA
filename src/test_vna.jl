
include("vna_control.jl")

vna = connectVNA()
setPowerLevel(vna,-20)
setAveraging(vna,false)
setFrequencies(vna,20.025e9,50e6)
setSweepPoints(vna,101)
setIFBandwidth(vna,Int(50e6))
setFormat2Log(vna)

trigger