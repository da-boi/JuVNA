
mutable struct Devices
    stagenames::Dict
    stagecals::Dict
    stagecolls::Dict
    stagezeros::Dict
    stageborders::Dict
    ids::Vector{DeviceId}
end



function move(booster::PhysicalBooster,newpos::Vector{Float64}; additive=false)
    if additive
        commandMove(devices::Vector{DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)

        checkCollision(booster.pos,booster.pos+newpos) && error("Discs are about to collide!")

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


function checkCollision(pos::Vector{<:Real},newpos::Vector{<:Real},)
    
end