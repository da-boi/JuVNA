include("../src/JuXIMC.jl")
include("../examplesdom/stages.jl")

infoXIMC()

devcount, devenum, enumnames = setupDevices(JuXIMC.ENUMERATE_PROBE | JuXIMC.ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
# JuXIMC.closeDevice(D[1:3])
# D = D[4]

commandMove(D,[20,20,20],stagecals)
commandMove(D,zeros(3),stagecals)
