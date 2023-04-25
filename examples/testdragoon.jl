# for testing purposes only

using Dragoon

include("../src/vna_control.jl")
include("../src/JuXIMC.jl")

include("stages.jl")

infoXIMC()

devcount, devenum, enumnames = setupDevices(JuXIMC.ENUMERATE_PROBE | JuXIMC.ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)
# JuXIMC.closeDevice(D[1:3])
# D = D[4]

commandMove(D,[20,20,20],stagecals)
commandMove(D,zeros(3),stagecals)

vna = connectVNA()
# instrumentSimplifiedSetup(vna)

devices = Devices(D,stagecals,stagecolls,stagezeros,stageborders)

b = PhysicalBooster(devices,)





