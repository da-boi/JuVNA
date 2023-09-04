using Plots
using JLD2
using LaTeXStrings

@load "../2_discs_scan_ref_and_hist_middle.jld2"

R = reshape((x->x.objvalue).(hist[1:end-1]),(21,21))

contourf(R; levels=20)


contourf(-10:1:10,-10:1:10,log10.(R); color=:turbo,levels=20,lw=0,aspect_ratio=:equal,clim=(0,2.3),colorbar_title=L"\log_{10} f_R")
plot!([-4,-4,4,4,-4],[-4,4,4,-4,-4]; c=:black,linestyle=:dash,legend=false)
xlims!((-10,10))
ylims!((-10,10))
xlabel!(L"\Delta x_1"*" [mm]")
ylabel!(L"\Delta x_2"*" [mm]")



x0 = [0.105,0.303]

d0 = pos2dist(x0)

boost1d()