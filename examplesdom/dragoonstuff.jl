


mutable struct Devices <: DevicesType
    ids::Vector{DeviceId}

    stagenames::Vector{String}
    stagecals::Vector{Tuple{Int,Symbol}}
    stagecolls::Vector{Tuple{Float64,}}
    stagezeros::Vector{Tuple{Float64,Float64}}
    stageborders::Vector{Tuple{Float64,Float64}}

    function Devices(ids,stagecals::Dict,stagecolls::Dict,stagezeros::Dict,stageborders::Dict)
        sn = [getStageName(D[i]) for i in eachindex(D)]
        scal = [stagecals[getStageName(D[i])] for i in eachindex(D)]
        sz = [stagezeros[getStageName(D[i])] for i in eachindex(D)]
        scol = [stagecolls[getStageName(D[i])] for i in eachindex(D)]
        sb = [stageborders[getStageName(D[i])] for i in eachindex(D)]


        new(ids,sn,scal,sz,scol,sb)
    end
end



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

function move(booster::PhysicalBooster,newpos::Vector{Float64}; additive=false)
    if additive
        checkCollision(booster.pos,booster.pos+newpos) && error("Discs are about to collide!")
        
        commandMove(devices::Vector{DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)

        booster.pos += newpos
        commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        commandWaitForStop(booster.devices.id)
    else
        checkCollision(booster.pos,newpos) && error("Discs are about to collide!")

        booster.pos = copy(newpos)
        
        commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        commandWaitForStop(booster.devices.id)
    end
end