# for testing purposes only

using Dragoon
using DelimitedFiles
using CSV

include("vna_control.jl")
#include(joinpath("JuXIMC.jl","src","JuXIMC.jl"))

include("JuXIMC.jl")
#include("stages.jl")

include("measurement.jl")

function saveS2P(fileURL)
    instrumentDirectSocket.sendall(b"MMEMory:STORe '" + bytes(fileURL,encoding="utf8") + b"'\n")
    return true
end


stagenames = Dict{String, Int}("Big Chungus" => 1, "Monica" => 2, "Alexanderson" => 3, "Bigger Chungus" => 4,)
stagecals  = Dict{String, Tuple{Symbol,Int}}("Big Chungus" => (:mm,80), "Monica" => (:mm,800), "Alexanderson" => (:mm,800), "Bigger Chungus" => (:mm,80))



JuXIMC.infoXIMC()

JuXIMC.setBindyKey(
    joinpath(
        dirname(@__DIR__),
        "XIMC\\ximc-2.13.6\\ximc\\win64\\keyfile.sqlite"
    )
)

devcount, devenum, enumnames = JuXIMC.setupDevices(JuXIMC.ENUMERATE_PROBE | JuXIMC.ENUMERATE_NETWORK,b"addr=134.61.12.184")

# ========================================================================================================================

D = JuXIMC.openDevices(enumnames,stagenames)
JuXIMC.checkOrdering(D,stagenames)
# JuXIMC.closeDevice(D[1:3])
# D = D[4]

#JuXIMC.commandMove(D,[20,20,20],stagecals)
#JuXIMC.commandMove(D,zeros(3),stagecals)

#DeviceID = D[4]
#pos  = 10000 
#upos = 0

#JuXIMC.commandMove(DeviceID,pos,upos)

vna = connectVNA()
instrumentSimplifiedSetup(vna, "{AAE0FD65-EEA1-4D1A-95EE-06B3FFCB32B7}", -20, 19E9, 3E9, 16384, 50000)


JuXIMC.commandMove(D[4],28000,0)
JuXIMC.command_wait_for_stop(D[4],0x00000a)
JuXIMC.commandWaitForStop(D[4])

data = []
filename = "newfile.csv" 


for i in 1:50
    println(i,", ",JuXIMC.getPos(D[4]))
    JuXIMC.commandMove(D[4],28000-500*i,0)
    JuXIMC.command_wait_for_stop(D[4],0x00000a)
    JuXIMC.commandWaitForStop(D[4])
  
    push!(data,getDataAsBinBlockTransfer(vna))
    #println(typeof(data))
    #println("Länge",length(data[i]))
    file = open(filename, "w")  
    writedlm(file, data, ',')
    close(file)
    sleep(0.1)
end


#print(data)




#=

devices = Devices(D,stagecals,stagecolls,stagezeros,stageborders)

function commandMove(devices::Devices,x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)
    if length(devices) != length(x)
        error("Amount of values don't match.")
    end

    for i in eachindex(devices)
        p = x2steps(x[i]; inputunit=inputunit,cal=cal[getStageName(devices[i])])

        info && println("\n D$i going to $x$inputunit = $(p[1]), $(p[2])")

        command_move(devices[i],p[1],p[2])
    end
end



function move(booster::Dragoon.PhysicalBooster,newpos::Vector{Float64}; additive=false)
    if additive
        commandMove(devices::Vector{JuXIMC.DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)

        checkCollision(booster.pos,booster.pos+newpos) && error("Discs are about to collide!")

        booster.pos += newpos
        JuXIMC.commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        JuXIMC.commandWaitForStop(booster.devices.id)
    else
        checkCollision(booster.pos,newpos) && error("Discs are about to collide!")

        booster.pos = copy(newpos)
        
        JuXIMC.commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        JuXIMC.commandWaitForStop(booster.devices.id)
    end
end

function checkCollision(pos::Vector{<:Real},newpos::Vector{<:Real},)
    return false
end

#b = Dragoon.PhysicalBooster(devices,)


=#

for res in 1:10 
    stepSize = res*80
    vNum = 16000/stepSize
    println(vNum)
end

res = 2
stepSize, vNum = setStepsize(res)
    



data = readMeasurement("TESTTESTTEST_2023-07-31_1.jld2")

println(data.data)








































#=

def measurement():
    test_info(lib, device_id)
    test_status(lib, device_id)
    test_set_microstep_mode_256(lib, device_id)
    test_set_speed(lib, device_id, 250)
    test_move(lib, device_id, 0, 0)
    test_wait_for_stop(lib, device_id, 100)
    startpos, ustartpos = test_get_position(lib, device_id)
    
    triggerContinuous()
    
    for i in range(step_num):
        test_move(lib, device_id, -step_size*i, 0)
        test_wait_for_stop(lib, device_id, 100)
        saveS2P("d:/AlexDeslis/meas_" + str(step_size*i) + ".s2p")       #saveS2P("d:/AlexDeslis/meas_" + str(1000*i) + ".s2p")
        time.sleep(waitTime)
        
    test_set_speed(lib, device_id, 500)
    test_move(lib, device_id, 0, 0)
    test_wait_for_stop(lib, device_id, 100)
    
    triggerHold()
    
    return True



        
instrumentErrCheck()

instrumentSimplifiedSetup()

triggerFreeRun()
            

        

measurement()
=#

