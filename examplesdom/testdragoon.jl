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

closeDevice(D[3],D[4])
D = D[1:2]


# commandMove(D,[0,0],stagecals)
# commandMove(D,[50,50],stagecals)

getPosition(D,stagecals)

# vna = connectVNA()
# instrumentSimplifiedSetup(vna)

freqs = genFreqs(22.025e9,50e6; length=10);
freqsplot = genFreqs(22.025e9,150e6; length=1000);

devices = Devices(D,stagecals,stagecols,stagezeros,stageborders);
b = PhysicalBooster(devices);
b.epsilon = 9.;



homeZero(b)
move(b,[0.05,0.05]; additive=true)


hist = initHist(b,100,freqs,(getObjAna1d,[]));

findInitPos(b,freqs,(getObjAna1d,[]),10,10,1*:mm)

s = initSimplexCoord(b.pos,0.005)
getSimplexObj(s,[1,2,3],b,hist,freqs,(getObjAna1d,[]); reset=true)

    
trace = nelderMead(b,hist,freqs,
                1.,1+2/b.ndisk,
                0.75-1/(2*b.ndisk),1-1/(b.ndisk),
                (getObjAna1d,[]),
                (initSimplexCoord!,[0.005]),
                (getSimplexObj,[]),
                (unstuckDont,[]);
                maxiter=Int(100),
                showtrace=true,
                showevery=100,
                unstuckisiter=true);

