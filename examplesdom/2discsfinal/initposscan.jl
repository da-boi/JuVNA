p0 = [0.013,0.027]

α = range(0.98; stop=1.0,length=101)


R = zeros(ComplexF64,128,length(α))


for i in eachindex(α)
    print("$i, ")
    move(b,p0*α[i]; additive=false);
    sleep(1)

    R[:,i] = getTraceN(vna,100)
end

plot(α,log10.(abs.(R[64,:])))
plot!(α,log10.(abs.(R[65,:])))


a = α[argmin(abs.(R[64,:]))]

move(b,p0*a)
getTraceN(vna,100)




clearBuffer(vna)
setCalibration(vna,"{58DE2545-34A1-49C4-8B5D-59D0B5E1435B}")

setFrequencies(vna,20.31e9,1.5e9)
setPowerLevel(vna,0)
setAveraging(vna,false)
setIFBandwidth(vna,Int(100e3))

send(vna, "CALCulate1:PARameter:SELect 'CH1_S11_1':*OPC?\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STATe ON\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STARt 36e-10\n")
send(vna, "CALCulate:MEASure:FILTER:TIME:STOP 9e-9;*OPC?\n")
send(vna, "CALCulate:MEASure:FORMat MLIN\n")

send(vna, "FORMat:DATA REAL,64;*OPC?\n") # Set the return type to a 64 bit Float
send(vna, "FORMat:BORDer SWAPPed;*OPC?\n") # Swap the byte order and wait for the completion of the commands

send(vna, "SENSe:SWEep:MODE SINGLe;*OPC?\n")
setSweepPoints(vna,128)
