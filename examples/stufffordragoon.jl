
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
        checkCollision(booster.pos,booster.pos+newpos) && error("Discs are about to collide!")
        
        commandMove(devices::Vector{JuXIMC.DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)

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