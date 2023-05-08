# for testing purposes only

using Dragoon

include("../src/vna_control.jl");
include("../src/JuXIMC.jl");
include("../examplesdom/dragoonstuff.jl");

include("../examplesdom/stages.jl");

infoXIMC();

devcount, devenum, enumnames =
    setupDevices(ENUMERATE_PROBE | ENUMERATE_NETWORK,b"addr=134.61.12.184");

# =========================================================================

D = openDevices(enumnames,stagenames)
checkOrdering(D,stagenames)

# closeDevice(D[3])
D = D[1:2]


commandMove(D,[0,0],stagecals)
commandMove(D,[10,10],stagecals)

getPosition(D,stagecals)

# vna = connectVNA()
# instrumentSimplifiedSetup(vna)

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders)

b = PhysicalBooster(devices)



homeZero(b)

move(b,[0.01,0.01]; additive=true)

commandMove(D,[10,10],stagecals)