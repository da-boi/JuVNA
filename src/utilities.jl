
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
        cal::Tuple{Symbol,Real}=(:mm,40),   # how many steps equal 1 inputunit
        microstepmode::MicrostepMode=MICROSTEP_MODE_FRAC_256,
    )

    s = x*inputunit*cal[2]/cal[1]
    µs = trunc(Int,2^(Int(microstepmode)-1)*(s%1))
    
    if 0 <= µs < 2^(microstepmode-1)
        return (floor(Int,s),µs)
    else
        return (floor(Int,s)+µs//(2^(microstepmode-1)),µs%(2^(microstepmode-1)))
    end
end

const x2s = x2steps

function steps2x(
        pos::Tuple{Integer,Integer};
        outputunit::Symbol=:m,
        cal::Tuple{Symbol,Real}=(:mm,40),
        microstepmode::MicrostepMode=MICROSTEP_MODE_FRAC_256
    )
    
    return (pos[1]+pos[2]/(2^(microstepmode-1)))*cal[1]/cal[2]/outputunit
end

function steps2x(
        pos::Integer,
        upos::Integer;
        outputunit::Symbol=:m,
        cal::Tuple{Symbol,Real}=(:mm,40),
        microstepmode::MicrostepMode=MICROSTEP_MODE_FRAC_256
    )

    return (pos+upos/(2^(microstepmode-1)))*cal[1]/cal[2]/outputunit
end

const s2x = steps2x

function plotRef(ref; freqs=Nothing,freqsunit="G")
    if freqsunit == "k"
        u = 1e3
    elseif freqsunit == "M"
        u = 1e6
    elseif freqsunit == "G"
        u = 1e9
    end

    if freqs != Nothing
        p1 = plot(freqs/u,real.(ref); label="Real")
        plot!(p1,freqs/u,imag.(ref); label="Imag")

        xlabel!("f in $(freqsunit)Hz")
        ylabel!("Ref")

        p2 = plot(real.(ref),imag.(ref); label = "Ref")
        
        xlabel!("Real(Ref)")
        ylabel!("Imag(Ref)")

        p3 = plot(freqs/u,abs.(ref); yaxis=:log)

        xlabel!("f in $(freqsunit)Hz")
        ylabel!("Ref")
    else
        p1 = plot(real.(ref); label="Real")
        plot!(p1,imag.(ref); label="Imag")

        xlabel!("f_i")
        ylabel!("Ref")

        p2 = plot(real.(ref),imag.(ref); label = "Ref")
        
        xlabel!("Real(Ref)")
        ylabel!("Imag(Ref)")

        p3 = plot(abs.(ref); yaxis=:log)

        xlabel!("f_i")
        ylabel!("Ref")
    end

    display(p1)
    display(p2)
    display(p3)

    return p1, p2, p3
end



function groupDelay(ref::Vector{ComplexF64},freqs::Vector{Float64})
    if length(ref) != length(freqs)
        return error("Array lengths don't match up.")
    end

    r_ = abs2.(ref)

    return (r_[2:end]-r_[1:end-1])./(freqs[2:end]-freqs[1:end-1])
end

function makeScan(hist; n=20,l=2,clim=(-1,2),levels=30)
    R = reverse(reshape((x->x.objvalue).(hist[1:(2n+1)^2]),
        (2steps+1,2steps+1)));

    println(log10.(extrema(R)))

    scan = contourf(-l:l/n:l,-l:l/n:l,log10.(R);
        color=:turbo,levels=levels,lw=0,aspect_ratio=:equal,
        clim=clim)

    xlims!(scan,(-l,l)); ylims!(scan,(-l,l))

    return scan
end



function plotPath(p,hist::Vector{State},p0; l=2,u=1e-3)
    idx = findfirst(x->x.objvalue==0,hist)
    if isnothing(idx); idx = length(hist); else idx -= 1; end

    X = zeros(idx,2)

    for i in 1:idx
        X[i,:] = (hist[i].pos-p0)/u
    end

    p_ = plot!(deepcopy(p),X[:,1],X[:,2];
        c=:black,linewidth=0.5,legend=false)
    xlims!(p_,-l,l); ylims!(p_,-l,l)

    return p_
end

function plotPath(p,trace::Dragoon.Trace,p0; l=2,u=1e-3)
    X = zeros(length(trace),2)

    for i in eachindex(trace)
        X[i,:] = (hist[i].pos-p0)/u
    end

    p_ = plot!(deepcopy(p),X[:,1],X[:,2];
        c=:black,linewidth=0.5,legend=false)
    xlims!(p_,-l,l); ylims!(p_,-l,l)

    return p_
end

function plotSimplex(p,x::Matrix{Float64},p0; u=1e-3)
    if size(x,1) != 2; error("Simplex not 2d."); end

    plot!(p,([x[1,:]; x[1,1]].-p0)/u,([x[2,:]; x[2,1]].-p0)/u)
end

function plotPath(p,trace::Vector{Dragoon.NMTrace},p0; l=2,u=1e-3,showsimplex::Bool=false)
    if showsimplex
        p_ = deepcopy(plot)

        for i in eachindex(trace)
            plotSimplex(p,trace[i].x,p0; u=u)
        end
    else
        X = zeros(length(trace),2)

        for i in eachindex(trace)
            X[i,:] = (trace[i].x_-p0)/u
        end

        p_ = plot!(deepcopy(p),X[:,1],X[:,2];
            c=:black,linewidth=0.5,legend=false)
        xlims!(p_,-l,l); ylims!(p_,-l,l)

        return p_
    end
end