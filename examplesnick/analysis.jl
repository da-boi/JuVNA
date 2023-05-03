include("binaryIO.jl")

function calcFieldProportionality(S_perturbed::ComplexF64, S_unperturbed::ComplexF64, frequency::Float64)
    return Float64(sqrt(abs(abs(S_perturbed - S_unperturbed)) / frequency ))
end

function calcFieldProportionality(S_pertubed::Vector{ComplexF64}, S_unperturbed::ComplexF64, frequency::Float64)
    ret = Vector{Float64}(undef, 0)

    for S in S_pertubed
        push!(ret, calcFieldProportionality(S, S_unperturbed, frequency))
    end

    return ret
end

function calcFieldProportionality(S_perturbed::Vector{ComplexF64}, frequency::Float64)
    ret = Vector{Float64}(undef, 0)

    for S in S_perturbed
        push!(ret, calcFieldProportionality(S, S_perturbed[begin], frequency))
    end

    return ret
end

function calcFieldProportionality(S_perturbed::Matrix{ComplexF64}, frequency::Vector{Float64})
    ret = Vector{Vector{Float64}}(undef, 0)

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i,:], frequency[i]))
    end

    return Matrix(reduce(hcat, ret))
end

calcFieldProportionality(meas::Measurement) = calcFieldProportionality(meas.data, meas.freq)


function correctPosition(pos::Vector{Float64}, sweepPoints::Integer, sweepTime::Real, motorSpeed::Real)
    d = sweepTime * motorSpeed
    ret = Vector{Vector{Float64}}(undef, 0)
    
    for i in 1:sweepPoints
        push!(ret, (pos .+ i*d))
    end

    return Matrix(reduce(hcat, ret))
end

#correctPosition(meas::Measurement) = correctPosition(meas.pos, meas.VNAParameters.sweeppoints, meas.VNAParameters.sweeptime, meas.MotorParameter.speed)