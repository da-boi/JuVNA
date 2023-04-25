
# some random stuff

export x2steps, steps2x, Units

import Base: *, /

function *(i,u::Symbol)
    if haskey(Units,u)
        return i*Units[u]
    else
        error("Unit not supported.")
    end
end

function /(i,u::Symbol)
    if haskey(Units,u)
        return i/Units[u]
    else
        error("Unit not supported.")
    end
end

function setBindyKey(keyfilepath::String)
    set_bindy_key(Vector{UInt8}(keyfilepath))
end

function Base.String(str::NTuple)
    arr = collect(UInt8,str)

    return String(filter(x->x!=0,arr))
end

Units = Dict{Symbol,Float64}(
    :m  => 1.0,
    :cm => 1e-2,
    :mm => 1e-3,
    :µm => 1e-6,
    :nm => 1e-9,
    :s  => 1.0,
    :ms => 1e-3,
    :µs => 1e-6,
)

function x2steps(
        x::Real;        # input (in unit inputunit, duh)
        inputunit::Symbol=:mm,
        cal::Tuple{Real,Symbol}=(40,:mm),   # how many steps equal 1 inputunit
        microstepmode::MicrostepMode=MICROSTEP_MODE_FRAC_256,
    )

    s = x*inputunit*cal[1]/cal[2]
    µs = trunc(Int,2^(Int(microstepmode)-1)*(s%1))
    
    if 0 <= µs < 2^(microstepmode-1)
        return (floor(Int,s),µs)
    else
        return (floor(Int,s)+µs//(2^(microstepmode-1)),µs%(2^(microstepmode-1)))
    end
end

const x2s = x2steps

function steps2x(
        pos::Tuple{Int,Int};
        outputunit::Symbol=:m,
        cal::Tuple{Real,Symbol}=(40,:mm),
        microstepmode::MicrostepMode=MICROSTEP_MODE_FRAC_256
    )
    
    return (pos[1]+pos[2]/(2^(microstepmode-1)))*cal[2]/cal[1]/outputunit
end

const s2x = steps2x