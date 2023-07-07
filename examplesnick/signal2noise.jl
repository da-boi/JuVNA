using StatsBase
import Measurements
const uncertainty = Measurements

include("measurement.jl")
include("plot.jl")

function fitGaussian(meas::Measurement; xIntervall::Tuple{Real, Real}=(0, 0))
    # The sum of the field over every frequency
    E = calcFieldProportionality(meas) .*1000
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

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
    @. dGaussian(p, t) = -p[2]/p[4]*abs(t-p[3])*exp(-(t-p[3])^2 / (2*p[4]^2))
    meanEstimate = xCrop[findmax(yCrop)[2]]
    p0 = [1.0, 1.0, meanEstimate, 20,]


    # fitting
    model = SciPy.odr.Model(gaussian)
    data = SciPy.odr.Data(xCrop, yCrop)
    #data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    # fit results
    ndof = length(xCrop) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))

    return (p, pErr, chiq, ndof)
end


function fitGaussian(name::String, N::Vector{Integer})
    sigma = Vector{Real}(undef, 0)
    sigmaErr = Vector{Real}(undef, 0)
    peak = Vector{Real}(undef, 0)
    peakErr = Vector{Real}(undef, 0)
    for i in N
        filename = name*"_$(i).jld2"
        if isfile(filename)
            m = readMeasurement(filename)
            p, pErr, _, _ = fitGaussian(m)
            push!(sigma, p[4])
            push!(sigmaErr, pErr[4])
            push!(peak, (p[1]+p[2])*1e3)
            push!(peakErr, (sqrt(pErr[1]^2+pErr[2]^2))*1e3)
            #push!(sigma, uncertainty.measurement(p[4], pErr[4]))
            #push!(peak, uncertainty.measurement(p[1]+p[2], (sqrt(pErr[1]^2+pErr[2]^2)))*1e3)
        else
            error("File not found")
        end
    end

    #Sigma = uncertainty.weightedmean(sigma)
    #Peak = uncertainty.weightedmean(peak)
    Sigma= uncertainty.measurement(mean(sigma, Weights(1 ./ sigmaErr)), std(sigma, Weights(1 ./ sigmaErr))/sqrt(length(sigma)-1))
    Peak = uncertainty.measurement(mean(peak, Weights(1 ./ peakErr)), std(peak, Weights(1 ./ peakErr))/sqrt(length(peak)-1))

    return (Sigma, Peak)
end

fitGaussian(name::String, range::UnitRange) = fitGaussian(name, collect(Integer, range))
fitGaussian(name::String, n::Real) = fitGaussian(name, [n])



function signal2noise(meas::Measurement; band::Real=30)
    # The sum of the field over every frequency
    E = calcFieldProportionality(meas; normalize=false)
    y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]

    # The position vector
    uStep = 256
    steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos[begin+1:end])]
    x = steps .* motorConversionFactor

    # Errors on the data 
    xErr = 0.12
    yErr = 0.1

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
    meanEstimate = x[findmax(y)[2]]
    p0 = [1.0, 1.0, meanEstimate, 20,]


    # fitting
    model = SciPy.odr.Model(gaussian)
    data = SciPy.odr.Data(x, y)
    #data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()
    p = output.beta

    fit = gaussian(p, x)
    resid = y .- fit

    left = findnearest(x, x[begin]+band)+1
    right = findnearest(x, x[end]-band)-1


    #signal = p[2]
    #noise = std(y[begin:left])
    signal = p[1] + p[2]
    noise = p[1]

    signal = maximum(y)
    noise = mean([y[begin:left]; y[right:end]])

    return signal/noise
end


function plotSNR()
    power = [-20, -15, -10, -5, 0, 5, 9]
    snr = []
    snrErr = []
    for p in power
        temp = []
        for i in 1:5
            m = readMeasurement("../data/power/c2000_black150_cc3300_$(p)dB_2023-06-27_$(i).jld2")
            # if i == 1 plotHeatmap(m) end
            push!(temp, signal2noise(m; band=30))
        end
        push!(snr, mean(temp))
        push!(snrErr, std(temp)/sqrt(length(temp)-1))
    end

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. f(p, t) = p[1] + p[2]*t
    slopeEstimate = (snr[end]-snr[begin])/(power[end]-power[begin])
    p0 = [snr[5], slopeEstimate]

    xErr = 0.3

    # fitting
    model = SciPy.odr.Model(f)
    data = SciPy.odr.RealData(power, snr; sy=snrErr, sx=xErr)
    #data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    ndof = length(power) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    fit = f(p, power)

    println("Chi2 = $(chiq)")
    println("a = $(p[1])")
    println("b = $(p[2])")

    # Residuals
    resid = snr .- fit
    resid = resid
    residErr = @. sqrt((p[2]*xErr)^2 + snrErr^2)

    ### Plotting the data and fit ###
        
    plotData = plot(legend=:topleft)

    # Data points
    plotData = scatter!(power, snr; yerror=residErr, color=:indianred1, markersize=3, label="Data")
    plotData = plot!(power, fit; color=:indianred1, label=L"Linear fit $\chi^2 / n_\mathrm{DOF}=$" * Printf.@sprintf("%.2f", chiq/ndof))
    plotData = plot!(ylabel=L"$\mathrm{SNR}$")

    # Residuals
    plotRes = hline([0], color=:black)
    #plotRes = scatter!(xCrop, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = scatter!(power, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = plot!(ylabel="Residuals")
    plotRes = plot!(xlabel=L"$P$  $[\mathrm{dBm}]$")

    display(plot(plotData, plotRes; layout=grid(2, 1, heights=[3/4, 1/4]), link=:x))
end

power = [-20, -15, -10, -5, 0, 5, 9]
M = []
for p in power
    m = readMeasurement("../data/power/c2000_black150_cc3300_$(p)dB_2023-06-27_1.jld2")
    plotHeatmap(m; normalize=true)
    push!(M, m)
end

plotGaussianFit(M, string.(power).*" dBm"; normalize=true)