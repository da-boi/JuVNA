include("../src/JuXIMC.jl")
include("../examplesdom/stages.jl")

infoXIMC()

devcount, devenum, enumnames = setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
closeDevices(D[1:3])
D = D[4]

setSpeed(D, 500)
commandMove(D, 25000, 0)
commandMove(D, 28000, 0)