
# mutable struct Boundaries <: BoundariesType
#     lo::Float64
#     hi::Float64

#     function Boundaries()
#         new(0,0)
#     end

#     function Boundaries(hi,lo)
#         new(hi,lo)
#     end
# end

# function checkBoundaries(b::Boundaries)
#     if b.hi < b.lo
#         error("Boundary failure: hi < lo!")
#     end
# end





mutable struct Devices <: DevicesType
    ids::Vector{DeviceId}

    stagenames::Vector{String}
    stagecals::Vector{Tuple{Symbol,Float64}}
    stagezeros::Vector{Tuple{Symbol,Float64}}
    stagecols::Vector{Tuple{Symbol,Float64,Float64}}
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

import Dragoon: PhysicalBooster

function PhysicalBooster(devices::Devices; τ::Real=1e-3,ϵ::Real=24,maxlength::Real=2)

    b = PhysicalBooster(devices,zeros(length(devices.ids)),length(devices.ids),
        τ,ϵ,maxlength,0)

    b.pos = steps2pos(getPos(devices.ids; fmt=Vector),b; outputunit=:m)

    return b
end



function pos2steps(pos::Float64,
        stagecal::Tuple{Symbol,Float64},
        stagezero::Tuple{Symbol,Float64};
        inputunit=:m)

    return x2steps(pos*inputunit-stagezero[2]*stagezero[1];
        inputunit=:m,cal=stagecal)
end

function pos2steps(booster::PhysicalBooster; inputunit=:m)
    s = Array{Tuple{Int,Int}}(undef,booster.ndisk)

    for i in 1:booster.ndisk
        s[i] = pos2steps(booster.pos[i],booster.devices.stagecals[i],
            booster.devices.stagezeros[i]; inputunit=inputunit)
    end

    return s
end

function pos2steps(newpos::Vector{Float64},booster::PhysicalBooster;
        inputunit=:m,additive=false)
    
    s = Array{Tuple{Int,Int}}(undef,booster.ndisk)
    
    if additive
        for i in 1:booster.ndisk
            s[i] = pos2steps(newpos[i]+booster.pos[i],booster.devices.stagecals[i],
                booster.devices.stagezeros[i]; inputunit=inputunit)
        end
    else
        for i in 1:booster.ndisk
            s[i] = pos2steps(newpos[i],booster.devices.stagecals[i],
                booster.devices.stagezeros[i]; inputunit=inputunit)
        end
    end

    return s
end

# function pos2steps(booster::PhysicalBooster; inputunit=:m)
#     return @. pos2steps(booster.pos,booster.devices.stagecals,
#         booster.devices.stagezeros; inputunit=inputunit)
# end



function steps2pos(steps::Tuple{Int,Int},
        stagecal::Tuple{Symbol,Float64},
        stagezero::Tuple{Symbol,Float64},;
        outputunit=:m)
    
    return steps2x(steps; outputunit=outputunit,cal=stagecal) +
        stagezero[2]*stagezero[1]/outputunit
end

function steps2pos(steps::Vector{Tuple{Int,Int}},booster::PhysicalBooster;
        outputunit=:m)
    
    p = Array{Float64}(undef,booster.ndisk)

    for i in 1:booster.ndisk
        p[i] = steps2pos(steps[i],booster.devices.stagecals[i],
            booster.devices.stagezeros[i]; outputunit=outputunit)
    end

    return p
end

# function steps2pos(steps::Vector{Tuple{Int,Int}},booster::PhysicalBooster;
#         outputunit=:m)

#     return @. steps2pos(steps,booster.devices.stagecals,
#         booster.devices.stagezeros; outputunit=outputunit)
# end




function getPos(booster::PhysicalBooster)
    return steps2pos(getPos(b.devices.ids; fmt=Vector),b)
end






function checkCollision(pos::Vector{Float64},
        booster::PhysicalBooster)
    
    for i in 1:booster.ndisk-1
        b1 = booster.devices.stageborders[i]
        b2 = booster.devices.stageborders[i+1]

        if pos[i+1]-pos[i] < 0
            return true
        elseif pos[i+1]-pos[i] < b1[3]/b1[1]-b2[2]/b2[1]
            return true
        end
    end

    return false
end

function checkCollision(pos::Vector{Float64},newpos::Vector{Float64},
        booster::PhysicalBooster; steps::Int=10, additive::Bool=false)
    
    if additive
        for i in 1:steps
            if checkCollision(pos+newpos*i/steps,booster)
                return true
            end
        end

        return false
    else
        for i in 1:steps
            if checkCollision(pos+(newpos-pos)*i/steps,booster)
                return true
            end
        end

        return false
    end
end



function commandMove(devices::Vector{DeviceId},positions::Vector{Tuple{Int,Int}})
    if length(devices) != length(positions)
        error("Device number and position number don't match.")
    end
    
    for i in eachindex(devices)
        commandMove(devices[i],positions[i][1],positions[i][2])
    end
end

function move(booster::PhysicalBooster,newpos::Vector{Float64}; additive=false)
    if additive
        checkCollision(booster.pos+newpos,booster) && error("Discs are about to collide!")
        
        booster.pos += newpos

        commandMove(booster.devices.ids,pos2steps(newpos,booster; additive=additive))
        commandWaitForStop(booster.devices.ids)
    else
        checkCollision(newpos,booster) && error("Discs are about to collide!")

        booster.pos = copy(newpos)
        
        commandMove(booster.devices.ids,pos2steps(newpos,booster; additive=additive))
        commandWaitForStop(booster.devices.ids)
    end
end

function homeZero(booster::PhysicalBooster)
    commandMove(booster.devices.ids,zeros(Int32,booster.ndisk,2))
    commandWaitForStop(booster.devices.ids)
    booster.pos = getPos(b)
end

function homeHome(booster::PhysicalBooster)
    return 
end