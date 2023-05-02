
mutable struct Boundaries <: Dragoon.BoundariesType
    lo::Float64
    hi::Float64

    function Boundaries()
        new(0,0)
    end

    function Boundaries(hi,lo)
        new(hi,lo)
    end
end

function checkBoundaries(b::Boundaries)
    if b.hi < b.lo
        error("Boundary failure: hi < lo!")
    end
end





mutable struct Devices <: DevicesType
    ids::Vector{DeviceId}

    stagenames::Vector{String}
    stagecals::Vector{Tuple{Symbol,Float64}}
    stagecols::Vector{Tuple{Symbol,Float64,Float64}}
    stagezeros::Vector{Tuple{Symbol,Float64}}
    stageborders::Vector{Tuple{Symbol,Float64,Float64}}

    function Devices(ids,stagecals::Dict,stagecols::Dict,stagezeros::Dict,stageborders::Dict)
        sn = [getStageName(D[i]) for i in eachindex(D)]
        scal = [stagecals[getStageName(D[i])] for i in eachindex(D)]
        sz = [stagezeros[getStageName(D[i])] for i in eachindex(D)]
        scol = [stagecols[getStageName(D[i])] for i in eachindex(D)]
        sb = [stageborders[getStageName(D[i])] for i in eachindex(D)]

        new(ids,sn,scal,sz,scol,sb)
    end
end



function pos2steps(pos::Float64,
        stagecal::Tuple{Symbol,Float64},
        stagezero::Tuple{Symbol,Float64},;
        inputunit=:m)

    return x2steps(pos/inputunit-stagezero[2]/stagezero[1];
        inputunit=:m,cal=stagecal)
end

function pos2steps(booster::PhysicalBooster; inputunit=:m)
    s = Array{Int}(undef,booster.ndisk)

    for i in 1:booster.ndisk
        s[i] = pos2steps(booster.pos[i],booster.devices.stagecals[i],
            booster.devices.stagezeros[i]; inputunit=inputunit)
    end

    return s
end

function pos2steps(booster::PhysicalBooster; inputunit=:m)
    return @. pos2steps(booster.pos,booster.devices.stagecals,
        booster.devices.stagezeros; inputunit=inputunit)
end



function steps2pos(steps::Int,
        stagecal::Tuple{Symbol,Float64},
        stagezero::Tuple{Symbol,Float64},;
        outputunit=:m)
    
    return steps2x(steps; outputunit=outputunit,cal=stagecal) +
        stagezero[2]*stagezero[1]/outputunit
end




function checkCollision(pos::Vector{Float64},
        booster::PhysicalBooster)
    
    for i in 1:booster.ndisk-1
        if pos[i]-pos[i+1] < 0
            return true
        elseif pos[i]-pos[i+1] < booster.devices.stageborders[i][3]-
                booster.devices.stageborders[i+1][2]
            return true
        end
    end            
end

function checkCollision(pos::Vector{Float64},newpos::Vector{Float64},
        booster::PhysicalBooster; steps::Int=10)
    
    for i in 1:steps
        if checkCollision(pos+(newpos-pos)*i/steps,booster)
            return true
        end
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
        checkCollision(booster.pos+newpos,booster) && error("Discs are about to collide!")
        
        commandMove(devices::Vector{DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Int,Symbol}}; info=false,inputunit=:mm)

        booster.pos += newpos
        commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        commandWaitForStop(booster.devices.id)
    else
        checkCollision(newpos,booster) && error("Discs are about to collide!")

        booster.pos = copy(newpos)
        
        commandMove(booster.devices.ids,booster.pos,booster.devices.stagecals;
            inputunit=:m)
        commandWaitForStop(booster.devices.id)
    end
end