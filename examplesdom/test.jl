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

commandMove(D[4],28000,0)
commandWaitForStop(D[4])

data = []

for i in 1:30
    println(i,", ",getPos(D[4]))
    commandMove(D[4],28000-250*i,0)
    # command_wait_for_stop(D[4])
    commandWaitForStop(D[4])
    # sleep(1)

    push!(data,getDataAsBinBlockTransfer(vna))

    sleep(0.1)
end


