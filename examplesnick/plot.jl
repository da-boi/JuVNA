using Plots
using LaTeXStrings
import SciPy
import Printf

include("analysis.jl")
include("binaryIO.jl")

const motorConversionFactor::Float64 = 6 / 500 # mm / step

function plotHeatmap(meas::Measurement; color=:inferno)
    E = calcFieldProportionality(meas)

    # The position vector
    uStep = 256
    steps = [meas.pos[i].Position + meas.pos[i].uPosition/uStep for i in eachindex(meas.pos)]
    x = steps .* motorConversionFactor

    gr()
    heatmap(x, meas.freq.*1e-9, transpose(E);
        c=color,
        xlabel="Position [mm]",
        ylabel="Frequency [GHz]",
    )
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

function plotGaussianFit(p,meas::Measurement; color=:indianred1, xIntervall::Tuple{Real, Real}=(0, 0))

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
    data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()

    # fit results
    ndof = length(xCrop) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    pErr = sqrt.(getDiag(output.cov_beta))
    fit = gaussian(p, x)

    # Residuals
    resid = y .- fit
    resid = resid[a:b]
    residErr = @. sqrt( ($dGaussian(p, xCrop)*xErr)^2 + yErr^2 )

    
    ### Plotting the data and fit ###
    
    #plotData = plot!(legend=:topleft)

    # Fit intervall
    if xIntervall != (0, 0) plotData = vspan!([x[a],x[b]]; color=:gray, alpha=0.2, label="Fit Intervall") end

    # Data points
    plotData = scatter!(x, y; color=color, markersize=3, label="Data")
    plotData = plot!(ylabel=L"Sum of Amplitudes $\cdot 10^{-3}$")

    # Fit
    xFit = LinRange(x[begin], x[end], 200)
    fitCurve = gaussian(p, xFit)
    label_Fit = L"Fit $\sigma=$" * Printf.@sprintf("%.2f mm",p[4])
    label_mu = L"$\mu=$" * Printf.@sprintf("%.2f mm",p[3])
    plotData = plot!(xFit, fitCurve; color=color, label=label_Fit)
    plotData = vline!([p[3]], color=:royalblue1, linestyle=:dash, label=label_mu)


    # Residuals
    plotRes = hline([0], color=:black)
    #plotRes = scatter!(xCrop, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = scatter!(xCrop, resid; color=color, markersize=3, legend=false)
    plotRes = vline!([p[3]], color=:royalblue1, linestyle=:dash)
    plotRes = plot!(ylabel="Residuals")
    plotRes = plot!(xlabel="Position [mm]")

    plot(plotData, plotRes; layout=grid(2, 1, heights=[3/4, 1/4]), link=:x)

    return (plotData, plotRes, p, pErr, chiq, ndof)

end

function plotGaussianFit(M::Vector{Measurement}; color=:indianred1, xIntervall::Tuple{Real, Real}=(0, 0))

    meas = M[1]
    Meas = M[2]
    # The sum of the field over every frequency
    E = calcFieldProportionality(meas) .*1000
    y = dropdims(sum(E, dims=2), dims=2)[begin+1:end]
    E2 = calcFieldProportionality(Meas) .*1000
    Y = dropdims(sum(E2, dims=2), dims=2)[begin+1:end]

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
    YCrop = Y[a:b]
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
    P0 = [1.0, 1.0, 160, 20,]


    # fitting
    model = SciPy.odr.Model(gaussian)
    data = SciPy.odr.Data(xCrop, yCrop)
    Data = SciPy.odr.Data(xCrop, YCrop)
    data = SciPy.odr.RealData(xCrop, yCrop; sx=xErr, sy=yErr)
    odr = SciPy.odr.ODR(data, model, beta0=p0)
    output = odr.run()
    Odr = SciPy.odr.ODR(Data, model, beta0=P0)
    Output = Odr.run()


    # fit results
    ndof = length(xCrop) - length(p0)
    chiq = output.res_var*ndof
    p = output.beta
    P = Output.beta
    pErr = sqrt.(getDiag(output.cov_beta))
    fit = gaussian(p, x)

    # Residuals
    resid = y .- fit
    resid = resid[a:b]
    residErr = @. sqrt( ($dGaussian(p, xCrop)*xErr)^2 + yErr^2 )

    
    ### Plotting the data and fit ###

    
    X = x .- Output.beta[3]
    x = x .- output.beta[3]

    p[3] = 0
    P[3] = 0
    
    plotData = plot(legend=false)

    # Fit intervall
    if xIntervall != (0, 0) plotData = vspan!([x[a],x[b]]; color=:gray, alpha=0.2, label="Fit Intervall") end

    # Data points
    plotData = scatter!(x, y; color=color, markersize=3, label="Data")
    plotData = scatter!(X, Y; color=:royalblue1, markersize=3, label="Data")
    plotData = plot!(ylabel=L"Sum of Amplitudes $\cdot 10^{-3}$")

    # Fit
    xFit = LinRange(x[begin], x[end], 200)
    fitCurve = gaussian(p, xFit)
    XFit = LinRange(X[begin], X[end], 200)
    FitCurve = gaussian(P, XFit)
    label_Fit = L"Fit $\sigma=$" * Printf.@sprintf("%.2f mm",p[4])
    label_mu = L"$\mu=$" * Printf.@sprintf("%.2f mm",p[3])
    plotData = plot!(xFit, fitCurve; color=color, label=label_Fit)
    plotData = plot!(XFit, FitCurve; color=:royalblue1, label=label_Fit)


    # Residuals
    plotRes = hline([0], color=:black)
    #plotRes = scatter!(xCrop, resid; yerror=residErr, color=:indianred1, markersize=3, legend=false)
    plotRes = scatter!(xCrop, resid; color=color, markersize=3, legend=false)
    plotRes = vline!([p[3]], color=:royalblue1, linestyle=:dash)
    plotRes = plot!(ylabel="Residuals")
    plotRes = plot!(xlabel="Position [mm]")

    #display(plot(plotData, plotRes; layout=grid(2, 1, heights=[3/4, 1/4]), link=:x))
    display(plotData)

    return (plotData, plotRes, p, pErr, chiq, ndof)
end