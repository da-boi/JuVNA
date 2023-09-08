


mutable struct Devices <: DevicesType
    ids::Vector{DeviceId}

    stagenames::Vector{String}
    stagecals::Vector{Tuple{Symbol,Float64}}
    stagezeros::Vector{Tuple{Symbol,Float64}}
    stagecols::Vector{Tuple{Symbol,Float64,Float64}}
    stageborders::Vector{Tuple{Symbol,Float64,Float64}}
    stagehomes::Vector{Tuple{Symbol,Float64}}

    function Devices(ids,stagecals::Dict,stagecols::Dict,stagezeros::Dict,stageborders::Dict)
        sn = [getStageName(D[i]) for i in eachindex(D)]
        scal = [stagecals[getStageName(D[i])] for i in eachindex(D)]
        sz = [stagezeros[getStageName(D[i])] for i in eachindex(D)]
        scol = [stagecols[getStageName(D[i])] for i in eachindex(D)]
        sb = [stageborders[getStageName(D[i])] for i in eachindex(D)]

        new(ids,sn,scal,sz,scol,sb,[])
    end

    function Devices(ids,stagecals::Dict,stagecols::Dict,stagezeros::Dict,stageborders::Dict,stagehomes::Dict)
        sn = [getStageName(D[i]) for i in eachindex(D)]
        scal = [stagecals[getStageName(D[i])] for i in eachindex(D)]
        sz = [stagezeros[getStageName(D[i])] for i in eachindex(D)]
        scol = [stagecols[getStageName(D[i])] for i in eachindex(D)]
        sb = [stageborders[getStageName(D[i])] for i in eachindex(D)]
        sh = [stagehomes[getStageName(D[i])] for i in eachindex(D)]

        new(ids,sn,scal,sz,scol,sb,sh)
    end
end



import Dragoon: PhysicalBooster, unow



function PhysicalBooster(devices::Devices; τ::Real=1e-3,ϵ::Real=24,maxlength::Real=2)
    b = PhysicalBooster(devices,zeros(length(devices.ids)),length(devices.ids),
        τ,ϵ,maxlength,unow(),unow(),0)

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


function getPos(booster::PhysicalBooster)
    return steps2pos(getPos(booster.devices.ids; fmt=Vector),booster)
end

function updatePos!(booster::PhysicalBooster)
    booster.pos = getPos(booster)
end





function checkCollision(pos::Vector{Float64},
        booster::PhysicalBooster)
    
    for i in 1:booster.ndisk-1
        c1 = booster.devices.stagecols[i]
        c2 = booster.devices.stagecols[i+1]

        if pos[i+1] < pos[i]
            return true
        elseif pos[i+1]+c2[2]*c2[1] < pos[i]+c1[3]*c1[1] # pos[i+1]-pos[i] < c1[3]/c1[1]-c2[2]/c2[1]
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

function checkBorders(newpos::Vector{Float64},booster::PhysicalBooster; additive::Bool=false)
    for i in 1:booster.ndisk
        b = booster.devices.stageborders[i]

        if !(b[2]*b[1] <= booster.pos[i]*additive+newpos[i] <= b[3]*b[1])

            return true
        end
    end

    return false
end





function commandMove(devices::Vector{DeviceId},positions::Vector{Tuple{Int,Int}})
    if length(devices) != length(positions)
        error("Device number and position number don't match.")
    end
    
    for i in eachindex(devices)
        commandMove(devices[i],positions[i][1],positions[i][2])
    end

    return
end



import Dragoon: move

function Dragoon.move(booster::PhysicalBooster,newpos::Vector{Float64};
        additive=false, info::Bool=false)

    updatePos!(booster)

    info && println("Moving to ",booster.pos .* additive + newpos)

    checkCollision(booster.pos,newpos,booster; additive=additive) && begin
            println("Current pos:"); println.(booster.pos)
            println("New pos:"); println.(newpos+booster.pos.*additive)
            error("Discs are about to collide!")
        end

    checkBorders(newpos,booster;additive=additive) && begin
            println("Current pos:"); println.(booster.pos)
            println("New pos:"); println.(newpos+booster.pos.*additive)
            error("Discs are about to move out of bounds.")
        end

    # checkBorders(newpos,booster)
    
    t = unow()

    commandMove(booster.devices.ids,pos2steps(newpos,booster; additive=additive))
    commandWaitForStop(booster.devices.ids)

    booster.timestamp += unow() - t
    additive ? (booster.summeddistance += sum(abs.(newpos))) :
        (booster.summeddistance += sum(abs.(newpos-booster.pos)))

    info && println("Finished moving.")

    updatePos!(booster)

    return
end

function Dragoon.move(booster::PhysicalBooster,newpos::Vector{Tuple{Int64,Float64}};
        additive=true, info::Bool=false)

    newpos_ = copy(booster.pos)

    for n in newpos
        if additive
            newpos_[n[1]] += n[2]
        else
            newpos_[n[1]] = n[2]
        end
    end

    Dragoon.move(booster,newpos_; additive=false,info=info)
end





function homeZero(booster::PhysicalBooster)
    commandMove(booster.devices.ids,zeros(Int32,booster.ndisk,2))
    commandWaitForStop(booster.devices.ids)
    
    booster.pos = getPos(booster)
end

function homeHome(booster::PhysicalBooster)
    home = [h[2]*h[1] for h in booster.devices.stagehomes]

    println("Going home...")
    move(booster,home; additive=false,info=true)

    booster.pos = getPos(booster)
end





function findInitPos(booster::PhysicalBooster,freqs,objFunction,n1,n2,dx;
        start::Union{Nothing,Vector{Float64}}=nothing,home::Int=-1,reset::Bool=false)

    if home == 0
        homeZero(booster)
    elseif home == 1
        homeHome(booster)
    end

    reset && (x0 = copy(booster.pos))

    if start !== nothing
        move(booster,start)
    end

    obj = 0
    bestobj = 0
    bestpos = zeros(booster.ndisk)

    dx_ = ones(booster.ndisk)*dx

    for _ in 1:n1
        move(booster,dx_; additive=true)
        
        obj = getState(booster,freqs,objFunction).objvalue

        if obj < bestobj
            bestpos = copy(booster.pos)
        end
    end

    move(booster,bestpos)

    dx_ ./= (booster.ndisk:-1:1)

    for _ in 1:n2
        move(booster,dx_; additive=true)
        
        obj = getState(booster,freqs,objFunction).objvalue

        if obj < bestobj
            bestpos = copy(booster.pos)
        end
    end

    reset ? move(booster,x0) : move(booster,bestpos)

    return bestpos, bestobj
end