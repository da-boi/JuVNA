using Plots
using LaTeXStrings
import SciPy
import Printf
using StatsBase

# include("measurement.jl")

const motorConversionFactor::Float64 = 6 / 500 # mm / step

function plotHeatmap(meas::Measurement; color=:inferno, normalize=false)
    E = calcFieldProportionality(meas; normalize=normalize)

    # The position vector
    uStep = 256
    steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos)]
    x = steps .* motorConversionFactor

    plot = heatmap(x, meas.freq.*1e-9, transpose(E);
        c=color,
        xlabel="Position [mm]",
        ylabel=L"$f$ [GHz]",
        #colorbar_title=L"$F$ [s$^{1/2}$]",
        size=(400, 267)
    )

    display(plot)
    
    return
end

function plot2DHeatmap(meas::Measurement2D; color=:inferno, normalize=false, f=0)
    E = calcFieldProportionality(meas)
    if f == 0
        E = sum(E, dims=3)[:,:,1]
    else
        f_index = findnearest(meas.freq, f*1e9)
        E = E[:,:,f_index]
    end
    E = reverse(transpose(E); dims=1)

    # The position vector
    uStep = 256
    steps = [meas.pos[i, 1].Position + meas.pos[i, 1].uPosition/uStep for i in eachindex(meas.pos[:, 1])]
    x = steps .* motorConversionFactor
    y = meas.posSetY .* motorConversionFactor
    y .-= maximum(y)

    # x = [i for i in 1:size(E, 1)]
    # y = [i for i in 1:size(E, 2)]
    title = "Sum from $(meas.freq[begin]*1e-9) to $(meas.freq[end]*1e-9) GHz"
    if f != 0 title = L"f = "*Printf.@sprintf("%.2f GHz",meas.freq[f_index]*1e-9) end
    plot = heatmap(x, y, E;
        c=color,
        title=title,
        xlabel=L"x [\mathrm{mm}]",
        ylabel=L"y [\mathrm{mm}]"
        #colorbar_title=L"$F$ [s$^{1/2}$]",
        # size=(400, 267)
    )

    display(plot)
    
    return
end

# selected color schemes for the heatmap
# :inferno      # suitable for colorblind (default)
# :jet1         # like Alex
# :hot          # monochromatic
# :gist_gray    # grayscale

# returns the index of the element of A which is closest to x
findnearest(A, x) = findmin(abs.(A.-x))[2]

# returns the diagonal of the Matrix as a Vector
function getDiag(M::Matrix)
    lx = size(M, 1)
    ly = size(M, 2)
    if lx != ly
        error("Quadratic matrix expected")
    end
    
    ret = []
    for i in 1:lx
        push!(ret, M[i, i])
    end

    return ret
end

function plotGaussianFit(meas::Measurement; color=:indianred1, xIntervall::Tuple{Real, Real}=(0, 0), normalize::Bool=false)

    # The sum of the field over every frequency
    E = calcFieldProportionality(meas; normalize=normalize)
    y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]

    # The position vector
    uStep = 256
    steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos[begin+1:end])]
    x = steps .* motorConversionFactor

    # Crop the data to the specified intervall in which the fit is to be performed
    if xIntervall[begin] == 0 || xIntervall[begin] < x[begin]
        a = firstindex(x)
    else
        a = findnearest(x, xIntervall[begin])
    end
    if xIntervall[end] == 0 || xIntervall[end] > x[end]
        b = lastindex(x)
    else
        b = findnearest(x, xIntervall[end])
    end
    yCrop = y[a:b]
    xCrop = x[a:b]

    # Errors on the data 
    xErr = 0.01
    yErr = std([y[1:10]; y[end-10:end]])

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
    @. dGaussian(p, t) = -p[2]/p[4]*abs(t-p[3])*exp(-(t-p[3])^2 / (2*p[4]^2))
    meanEstimate = xCrop[findmax(yCrop)[2]]
    p0 = [1.0, 1.0, meanEstimate, 20,]


    # fitting
    model = SciPy.odr.Model(gaussian)
    data = SciPy.odr.Data(xCrop, yCrop)
    data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    # fit results
    ndof = length(xCrop) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))
    fit = gaussian(p, x)

    println("chiq/ndof = $(chiq/ndof)")

    # Residuals
    resid = y .- fit
    resid = resid[a:b]
    residErr = @. sqrt( ($dGaussian(p, xCrop)*xErr)^2 + yErr^2 )

    
    ### Plotting the data and fit ###
    
    plotData = plot(legend=:topright)

    # Fit intervall
    if xIntervall != (0, 0) plotData = vspan!([x[a],x[b]]; color=:gray, alpha=0.2, label="Fit Intervall") end

    # Data points
    plotData = scatter!(x, y; color=color, markersize=3, label="Data")
    plotData = plot!(ylabel=L"$\sum{F}$  $[\mathrm{arb. unit}]$")

    # Fit
    xFit = LinRange(x[begin], x[end], 200)
    fitCurve = gaussian(p, xFit)
    label_Fit = L"Fit $\chi^2 / n_\mathrm{DOF}=$" * Printf.@sprintf("%.2f", chiq/ndof)
    plotData = plot!(xFit, fitCurve; color=color, label=label_Fit)
    plotData = vline!([p[3]], color=:royalblue1, linestyle=:dash, label="")

    # Residuals
    plotRes = hline([0], color=:black)
    #plotRes = scatter!(xCrop, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = scatter!(xCrop, resid; yerror=residErr, color=color, markersize=3, legend=false)
    plotRes = vline!([p[3]], color=:royalblue1, linestyle=:dash)
    plotRes = plot!(ylabel="Residuals")
    plotRes = plot!(xlabel=L"Position $[\mathrm{mm}]$")

    p = plot(plotData, plotRes; layout=grid(2, 1, heights=[3/4, 1/4]), link=:x)
    display(p)

    return (plotData, plotRes, p, pErr, chiq, ndof)

end

function plotGaussianFit(Meas::Vector{Any}, mLabel::Vector{String}; xIntervall::Tuple{Real, Real}=(0, 0), normalize::Bool=false)

    # Instantiate plot
    plotData = plot(legend=:topright)
    plotData = plot!(ylabel=L"$\sum{F}$  $[\mathrm{m/s\sqrt{kg}}]$")
    plotData = plot!(xlabel=L"Position $[\mathrm{mm}]$")

    # Fit intervall
    if xIntervall != (0, 0) plotData = vspan!([x[a],x[b]]; color=:gray, alpha=0.2, label="Fit Intervall") end

    i = 0
    for meas in Meas
        i += 1
        # The sum of the field over every frequency
        E = calcFieldProportionality(meas; normalize=normalize)
        y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]

        # The position vector
        uStep = 256
        steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos[begin+1:end])]
        x = steps .* motorConversionFactor

        # Crop the data to the specified intervall in which the fit is to be performed
        if xIntervall[begin] == 0 || xIntervall[begin] < x[begin]
            a = firstindex(x)
        else
            a = findnearest(x, xIntervall[begin])
        end
        if xIntervall[end] == 0 || xIntervall[end] > x[end]
            b = lastindex(x)
        else
            b = findnearest(x, xIntervall[end])
        end
        yCrop = y[a:b]
        xCrop = x[a:b]

        # Errors on the data 
        xErr = 0.12
        yErr = 0.1

        # The gaussian model to which the Data is to be fitted
        # with p0 beeing an initial guess for the coefficients
        @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
        meanEstimate = xCrop[findmax(yCrop)[2]]
        p0 = [1.0, 1.0, meanEstimate, 20,]


        # fitting
        model = SciPy.odr.Model(gaussian)
        data = SciPy.odr.Data(xCrop, yCrop)
        data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
        odr = SciPy.odr.ODR(data, model, beta0=p0)
        output = odr.run()

        # fit results
        ndof = length(xCrop) - length(p0)
        chiq = output.res_var*ndof
        p = output.beta
        pErr = sqrt.(getDiag(output.cov_beta))
        fit = gaussian(p, x)

        ### Plotting the data and fit ###

        # shift to maximum
        x = x .- p[3]
        p[3] = 0

        # Data points
        plotData = scatter!(x, y; color=i, markersize=3, label=mLabel[i])
        #color = plotData[1][end][:seriescolor]

        # Fit
        xFit = LinRange(x[begin], x[end], 200)
        fitCurve = gaussian(p, xFit)
        label_Fit = L"Fit $\sigma=$" * Printf.@sprintf("%.2f mm",p[4])
        label_mu = L"$\mu=$" * Printf.@sprintf("%.2f mm",p[3])
        plotData = plot!(xFit, fitCurve; color=i, label="")
        #plotData = vline!([p[3]], color=:royalblue1, linestyle=:dash, label=label_mu)

    end
    x = xlims()[1] + (xlims()[2] - xlims()[1]) * 0.05
    y = ylims()[2]
    plotData = annotate!([(x, y, Plots.text(L"\cdot 10^{6}", 11, :black, :center))])

    display(plotData)

    return
end




### Analysis ###

function dBm2W(dBm::Real)
    return 10^(dBm/10)*1e-3
end

function calcFieldProportionality(S_perturbed::ComplexF64, S_unperturbed::ComplexF64, frequency::Float64, power::Real; normalize::Bool=false)
    n = 1
    if !normalize n = dBm2W(power) end
    return Float64(sqrt(abs(abs(S_perturbed - S_unperturbed)) * n / frequency )) * 1e6
end

function calcFieldProportionality(S_pertubed::Vector{ComplexF64}, S_unperturbed::ComplexF64, frequency::Float64, power::Real; normalize::Bool=false)
    ret = Vector{Float64}(undef, 0)

    for S in S_pertubed
        push!(ret, calcFieldProportionality(S, S_unperturbed, frequency, power; normalize=normalize))
    end

    return ret
end

function calcFieldProportionality(S_perturbed::Vector{ComplexF64}, frequency::Float64, power::Real; normalize::Bool=false)
    ret = Vector{Float64}(undef, 0)

    for S in S_perturbed
        push!(ret, calcFieldProportionality(S, S_perturbed[begin], frequency, power; normalize=normalize))
    end

    return ret
end

function calcFieldProportionality(S_perturbed::Matrix{ComplexF64}, frequency::Vector{Float64}, power::Real; normalize::Bool=false)
    ret = Vector{Vector{Float64}}(undef, 0)

    for i in eachindex(frequency)
        push!(ret, calcFieldProportionality(S_perturbed[i,:], frequency[i], power; normalize=normalize))
    end

    return Matrix(reduce(hcat, ret))
end

calcFieldProportionality(meas::Measurement; normalize::Bool=false) = calcFieldProportionality(meas.data, meas.freq, meas.param.power; normalize=normalize)

# function calcFieldProportionality(meas::Measurement2D; normalize::Bool=false)
#     s = (size(meas.data)..., length(meas.freq))
#     ret = Array{Float64, 3}(undef, s)

#     for k in eachindex(meas.freq)
#         S_unperturbed = meas.data[1, 1][k]
#         for j in 1:size(meas.data,2)
            
#             for i in 1:size(meas.data,1)
                
#                 ret[i, j, k] = calcFieldProportionality(meas.data[i, j][k], S_unperturbed, meas.freq[k], meas.param.power; normalize=normalize)
#             end
#         end
#     end

#     return ret
# end

function calcFieldProportionality(meas::Measurement2D; normalize::Bool=false)
    s = (size(meas.data)..., length(meas.freq))
    ret = Array{Float64, 3}(undef, s)

    for k in eachindex(meas.freq)
        # S_unperturbed = meas.data[1, 1][k]
        S_unperturbed = mean([meas.data[begin, begin][k],  meas.data[begin, end][k],  meas.data[begin, end][k],  meas.data[end, end][k]])
        # S_unperturbed = mean([meas.data[begin, begin][k],  meas.data[begin, end][k]])


        for j in 1:size(meas.data, 2), i in 1:size(meas.data, 1)
            ret[i, j, k] = calcFieldProportionality(meas.data[i, j][k], S_unperturbed, meas.freq[k], meas.param.power)

        end
    end

    return ret
end

# function calcFieldProportionality(meas::Measurement2D; normalize::Bool=false)
#     s = (size(meas.data)..., length(meas.freq))
#     ret = Array{Float64, 3}(undef, s)

#     for k in eachindex(meas.freq)
#         for j in 1:size(meas.data,2)
#             ret[:, j, k] = calcFieldProportionality([e[1] for e in meas.data[:,j]], meas.freq[k], meas.param.power; normalize=normalize)
#         end
#     end

#     return ret
# end


function correctPosition(pos::Vector{Float64}, sweepPoints::Integer, sweepTime::Real, motorSpeed::Real)
    d = sweepTime * motorSpeed
    ret = Vector{Vector{Float64}}(undef, 0)
    
    for i in 1:sweepPoints
        push!(ret, (pos .+ i*d))
    end

    return Matrix(reduce(hcat, ret))
end