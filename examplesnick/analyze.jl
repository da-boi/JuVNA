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
    Sigma= uncertainty.measurement(mean(sigma, Weights(1 ./ sigmaErr)), std(sigma, Weights(1 ./ sigmaErr)))#/sqrt(length(sigma)-1))
    Peak = uncertainty.measurement(mean(peak, Weights(1 ./ peakErr)), std(peak, Weights(1 ./ peakErr)))#/sqrt(length(peak)-1))

    return (Sigma, Peak)
end

fitGaussian(name::String, range::UnitRange) = fitGaussian(name, collect(Integer, range))
fitGaussian(name::String, n::Real) = fitGaussian(name, [n])

label = ["1000", "2000", "3200"]
res = []
push!(res, fitGaussian("../data/method/s_black150_cc3300_9dB_2023-06-27", Vector{Integer}([2, 6, 8, 12, 20])))
push!(res, fitGaussian("../data/method/c1000_black150_cc3300_9dB_2023-06-27", Vector{Integer}([1, 2, 3, 4, 5])))
push!(res, fitGaussian("../data/method/c2000_black150_cc3300_9dB_2023-06-27", Vector{Integer}([1, 7, 8, 9, 10])))
push!(res, fitGaussian("../data/method/c3200_black150_cc3300_9dB_2023-06-27", Vector{Integer}([7, 8, 10, 11])))

dif = []
for i in 2:4
    sigma = abs(res[1][1] - res[i][1])
    peak = abs(res[1][2] - res[i][2])
    println(res[i][2])
    println(label[i-1]*": diff sigma= $(sigma),\t diff peak = $(peak)")
end







l = ["Discrete", "12.5 mm/s", "25 mm/s", "40 mm/s"]
M = []
push!(M, readMeasurement("../data/method/s_black150_cc3300_9dB_2023-06-27_8.jld2"))
push!(M, readMeasurement("../data/method/c1000_black150_cc3300_9dB_2023-06-27_1.jld2"))
push!(M, readMeasurement("../data/method/c2000_black150_cc3300_9dB_2023-06-27_7.jld2"))
push!(M, readMeasurement("../data/method/c3200_black150_cc3300_9dB_2023-06-27_7.jld2"))
plotGaussianFit(M, l)
for m in M
    plotHeatmap(m)
end