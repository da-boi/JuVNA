function calcFieldProportionality(S_perturbed::Float64, S_unperturbed::Float64, frequency::Float64)
    return Float64(sqrt(abs( (S_perturbed - S_unperturbed) / frequency )))
end

function calcFieldProportionality(S_perturbed::Vector{Float64}, S_unperturbed::Vector{Float64}, frequency::Vector{Float64})
    ret = Vector{Float64}(undef, 0)

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i], S_unperturbed[i], frequency[i]))
    end

    return ret
end

#=
function calcFieldProportionality(S_perturbed::Matrix{Float64}, S_unperturbed::Vector{Float64}, frequency::Vector{Float64})
    ret = Matrix{Float64}(undef, 0)

    for S in S_perturbed
        push!(ret, calcFieldProportionality(S, S_unperturbed, frequency))
    end

    return ret
end
=#

function calcFieldProportionality(S_perturbed::Matrix{Float64}, frequency::Vector{Float64})
    ret = Vector{Vector{Float64}}(undef, 0)

    for S in eachcol(S_perturbed)
        push!(ret, calcFieldProportionality(Vector(S), S_perturbed[:,begin], frequency))
    end

    return Matrix(reduce(hcat, ret))
end