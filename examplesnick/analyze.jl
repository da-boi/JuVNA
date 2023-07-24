using StatsBase
import Measurements
const uncertainty = Measurements

include("measurement.jl")
include("plot.jl")

function fitGaussian(meas::Measurement; xIntervall::Tuple{Real, Real}=(0, 0))
    # The sum of the field over every frequency
    E = calcFieldProportionality(meas; normalize=false)
    y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]

    # The position vector
    uStep = 256
    steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos[begin+1:end])]
    x = steps .* motorConversionFactor

    # Errors on the data 
    xErr = 0.1
    yErr = std([y[begin:10]; y[end-10:end]])

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
    @. dGaussian(p, t) = -p[2]/p[4]*abs(t-p[3])*exp(-(t-p[3])^2 / (2*p[4]^2))
    meanEstimate = x[findmax(y)[2]]
    p0 = [1.0, 1.0, meanEstimate, 20,]


    # fitting
    model = SciPy.odr.Model(gaussian)
    #data = SciPy.odr.Data(xCrop, yCrop)
    data = SciPy.odr.RealData(x, y; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    # fit results
    ndof = length(x) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))

    return (p, pErr, chiq, ndof)
end

function fitGaussian2(name::String, N::Vector{Integer})
    yArray = []
    x = []
    xErr = 0.1
    for i in N
        filename = name*"_$(i).jld2"
        if isfile(filename)
            m = readMeasurement(filename)
            E = calcFieldProportionality(m)
            push!(yArray, dropdims(sum(E, dims=2), dims=2)[begin+1:end])

            # The position vector
            uStep = 256
            steps = [m.pos[i].Position + m.pos[i].uPosition/uStep for i in eachindex(m.pos[begin+1:end])]
            x = steps .* motorConversionFactor
        else
            error("File not found")
        end
    end

    yMatrix = Matrix(reduce(hcat, yArray))
    y = mean(yMatrix, dims=2)
    y = dropdims(y, dims=2)

    # Errors on the data 
    yErr = std(yMatrix, dims=2) / sqrt(size(yMatrix, 2)-1)
    yErr = dropdims(yErr, dims=2)
    xErr = [0.1 for _ in 1:length(x)]

    println(mean(yErr))
    println(std([y[1:5]; y[end-5:end]]))

    # The gaussian model and the derivative to which the Data is to be fitted
    # with p0 beeing an initial guess for the coefficients
    @. gaussian(p, t) = p[1] + p[2]*exp(-(t-p[3])^2 / (2*p[4]^2))
    @. dGaussian(p, t) = -p[2]/p[4]*abs(t-p[3])*exp(-(t-p[3])^2 / (2*p[4]^2))
    meanEstimate = x[findmax(y)[2]]
    p0 = [1.0, 1.0, meanEstimate, 20,]

    # fitting
    model = SciPy.odr.Model(gaussian)
    #data = SciPy.odr.Data(x, y)
    data = SciPy.odr.RealData(x, y; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    # fit results
    ndof = length(x) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))

    Sigma = uncertainty.measurement(p[4], pErr[4])
    Peak = uncertainty.measurement(p[1]+p[2], sqrt(pErr[1]^2+p[2]^2))

    return (Sigma, Peak)
end

fitGaussian2(name::String, range::UnitRange) = fitGaussian2(name, collect(Integer, range))
fitGaussian2(name::String, n::Real) = fitGaussian2(name, [n])


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
            push!(peak, (p[1]+p[2]))
            push!(peakErr, (sqrt(pErr[1]^2+pErr[2]^2)))
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


function calcPeakDif()
    M = []
    S = []

    n = 5

    speed = [1000, 1500, 2000, 2600, 3200]
    for s in speed
        Dif = []

        for i in 1:n
            f = readMeasurement("../data/direction3/c$(s)_forward_black150_cc3300_9dBm_2023-07-17_$(i).jld2")
            b = readMeasurement("../data/direction3/c$(s)_backward_black150_cc3300_9dBm_2023-07-17_$(i).jld2")

            f_fit = fitGaussian(f)
            b_fit = fitGaussian(b)

            f_peak = uncertainty.measurement(f_fit[1][3], f_fit[2][3])
            b_peak = uncertainty.measurement(b_fit[1][3], b_fit[2][3])
            
            dif = b_peak - f_peak

            push!(Dif, dif)
        end

        mean = uncertainty.value(uncertainty.weightedmean(Dif))
        s = std(uncertainty.value.(Dif), Weights(1 ./ (uncertainty.uncertainty.(Dif)).^2) )
    
        push!(M, mean)
        push!(S, s)
    end

    speed *= motorConversionFactor

    println(speed)
    println(M)
    println(S)

    @. f(p, t) = p[1] + p[2]*t
    slopeEstimate = (M[end]-M[begin])/(speed[end]-speed[begin])
    p0 = [0, slopeEstimate]

    xErr = 0.1
    yErr = S ./ sqrt(n-1)

    # fitting
    model = SciPy.odr.Model(f)
    data = SciPy.odr.RealData(speed, M; sy=yErr, sx=xErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    ndof = length(speed) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))
    fit = f(p, speed)

    println("Chi2 = $(chiq)")
    println("a = $(p[1]) +- $(pErr[1])")
    println("b = $(p[2]) +- $(pErr[2])")

    # Residuals
    resid = M .- fit
    residErr = @. sqrt((p[2]*xErr)^2 + yErr^2)

    ### Plotting the data and fit ###
        
    plotData = plot(legend=:topleft)

    # Data points
    plotData = scatter!(speed, M; yerror=residErr, color=:indianred1, markersize=3, label="Data")
    plotData = plot!(speed, fit; color=:indianred1, label=L"Linear fit $\chi^2 / n_\mathrm{DOF}=$" * Printf.@sprintf("%.2f", chiq/ndof))
    plotData = plot!(ylabel=L"$\Delta{x}$  $[mm]$")

    # Residuals
    plotRes = hline([0], color=:black)
    #plotRes = scatter!(xCrop, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = scatter!(speed, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = plot!(ylabel="Residuals")
    plotRes = plot!(xlabel=L"$v$  $[\mathrm{mm/s}]$")

    display(plot(plotData, plotRes; layout=grid(2, 1, heights=[3/4, 1/4]), link=:x))
end

function calcMethodDif()
    Res = []

    push!(Res, fitGaussian("../data/direction3/s_forward_black150_cc3300_9dBm_2023-07-17", 1:5))
    push!(Res, fitGaussian("../data/direction3/c1000_forward_black150_cc3300_9dBm_2023-07-17", 1:5))
    push!(Res, fitGaussian("../data/direction3/c2000_forward_black150_cc3300_9dBm_2023-07-17", 1:5))
    push!(Res, fitGaussian("../data/direction3/c3200_forward_black150_cc3300_9dBm_2023-07-17", 1:5))

    std = []
    peak = []
    for i in 2:4
        push!(std, Res[1][1]-Res[i][1])
        push!(peak, Res[1][2]-Res[i][2])
    end

    println(std)
    println(peak)
end

function calcStrings()
    strings = ["floss", "black150", "supplemax", "garn", "NiCr", "mbz"]
    for string in strings
        sigmaF, peakF = fitGaussian("../data/strings/c2000_forward_$(string)_cc3300_9dBm_2023-07-17", 1:10)
        sigmaB, peakB = fitGaussian("../data/strings/c2000_backward_$(string)_cc3300_9dBm_2023-07-17", 1:10)

        sigma = uncertainty.weightedmean([sigmaF, sigmaB])
        peak = uncertainty.weightedmean([peakF, peakB])
        println("$(string) : sigma = $(sigma), peak = $(peak)")
    end
end

# l = ["Discrete", "12.5 mm/s", "25 mm/s", "40 mm/s"]
# M = []
# push!(M, readMeasurement("../data/direction2/s_forward_black150_cc3300_9dBm_2023-07-17_1.jld2"))
# push!(M, readMeasurement("../data/direction2/c1000_forward_black150_cc3300_9dBm_2023-07-17_1.jld2"))
# push!(M, readMeasurement("../data/direction2/c2000_forward_black150_cc3300_9dBm_2023-07-17_1.jld2"))
# push!(M, readMeasurement("../data/direction2/c3200_forward_black150_cc3300_9dBm_2023-07-17_1.jld2"))
# plotGaussianFit(M, l)
# for m in M
#     plotHeatmap(m)
# end

l = ["Floss", "Dandyline", "Supplemax", "Garn", "NiCr", "MBZ nano"]
M = []
push!(M, readMeasurement("../data/strings/c2000_backward_floss_cc3300_9dBm_2023-07-17_1.jld2"))
push!(M, readMeasurement("../data/strings/c2000_backward_black150_cc3300_9dBm_2023-07-17_1.jld2"))
push!(M, readMeasurement("../data/strings/c2000_backward_supplemax_cc3300_9dBm_2023-07-17_1.jld2"))
push!(M, readMeasurement("../data/strings/c2000_backward_garn_cc3300_9dBm_2023-07-17_1.jld2"))
push!(M, readMeasurement("../data/strings/c2000_backward_NiCr_cc3300_9dBm_2023-07-17_1.jld2"))
push!(M, readMeasurement("../data/strings/c2000_backward_mbz_cc3300_9dBm_2023-07-17_1.jld2"))
plotGaussianFit(M, l)
for m in M
    println(signal2noise(m))
end