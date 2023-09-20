using Statistics
using LaTeXStrings

function plotTerm(T,sigx; threshold=-10_000,maxt=Inf,maxdist=Inf,
        annpos=[(0.95,0.2),(0.95,0.2),(0.95,0.2),(0.95,0.2)],ylims=(-15,0.1))
    obj = T[:,1,:]
    ttot = T[:,2,:]
    dist = T[:,3,:]


    lx1 = min(maximum(ttot),maxt)

    p1 = scatter(ttot,obj/1e3; legend=false,markersize=2,layout=grid(2,2),
        yflip=true)

    xlims!(p1,(0,lx1*1.01)); ylims!(p1,ylims)

    for s in eachindex(sigx)
        N = size(T,1); nsuccess = sum(T[:,1,s] .<= threshold)
        succ = nsuccess/N; avg = round(Int,mean(T[:,1,s]))

        annotate!(p1[s],lx1*annpos[s][1],ylims[1]*annpos[s][2],
            (
                L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                L"\eta="*"$succ\n"*
                L"\overline{f_{\beta,F}}="*"$avg",
                8,:black,:right
            ))
    end

    plot!(p1[1]; xformatter=:none,bottom_margin=(-3.5,:mm),right_margin=(0.,:mm))
    plot!(p1[2]; xformatter=:none, yformatter=:none,bottom_margin=(-3.5,:mm),
        left_margin=(-3.5,:mm))
    plot!(p1[3]; top_margin=(0.,:mm),xlabel=" ",ylabel=" ")
    plot!(p1[4]; yformatter=:none,left_margin=(-3.5,:mm))

    annotate!(p1[3],lx1,3,(L"\sum\Delta t"*" [s]",12,:black,:center))
    annotate!(p1[3],-0.175*lx1,-16,(L"f_{\beta,F}\times 10^3",12,90.,:center,:black))

    display(p1)

    
    lx2 = min(maximum(dist)/1e-3,maxdist)

    p2 = scatter(dist/1e-3,obj/1e3; legend=false,markersize=2,layout=grid(2,2),
        yflip=true)

    xlims!(p2,(0,lx2*1.01)); ylims!(p2,ylims)

    for s in eachindex(sigx)
        N = size(T,1); nsuccess = sum(T[:,1,s] .<= threshold)
        succ = nsuccess/N; avg = round(Int,mean(T[:,1,s]))

        annotate!(p2[s],lx2*annpos[s][1],ylims[1]*annpos[s][2],
            (
                L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                L"\eta="*"$succ\n"*
                L"\overline{f_{\beta,F}}="*"$avg",
                8,:black,:right
            ))
    end

    plot!(p2[1]; xformatter=:none,bottom_margin=(-3.5,:mm),right_margin=(0.,:mm))
    plot!(p2[2]; xformatter=:none, yformatter=:none,bottom_margin=(-3.5,:mm),
        left_margin=(-3.5,:mm))
    plot!(p2[3]; top_margin=(0.,:mm),xlabel=" ",ylabel=" ")
    plot!(p2[4]; yformatter=:none,left_margin=(-3.5,:mm))

    annotate!(p2[3],lx2,3,(L"\sum\Delta X"*" [mm]",12,:center,:black))
    annotate!(p2[3],-0.175*lx2,-16,(L"f_{\beta,F}\times 10^3",12,90.,:center,:black))

    display(p2)

    return p1, p2
end


function plotTerm1(T,sigx; threshold=-10_000,maxt=Inf,maxdist=Inf)
    obj = T[:,1,:]
    ttot = T[:,2,:]
    dist = T[:,3,:]


    lx1 = min(maximum(ttot),maxt)

    p1 = scatter(ttot,obj/1e3; legend=false,markersize=2,layout=grid(2,2),
        yflip=true)

    xlims!(p1,(0,lx1*1.01)); ylims!(p1,(-15,0.1))

    for s in eachindex(sigx)
        N = size(T,1); nsuccess = sum(T[:,1,s] .<= threshold)
        succ = nsuccess/N; avg = round(Int,mean(T[:,1,s]))

        if s == 4
            annotate!(p1[s],lx1*0.05,-8,
                (
                    L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                    L"\eta="*"$succ\n"*
                    L"\overline{f_{\beta,F}}="*"$avg",
                    8,:black,:left
                ))
        else
            annotate!(p1[s],lx1*0.95,-3,
                (
                    L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                    L"\eta="*"$succ\n"*
                    L"\overline{f_{\beta,F}}="*"$avg",
                    8,:black,:right
                ))
        end
    end

    plot!(p1[1]; xformatter=:none,bottom_margin=(-3.5,:mm),right_margin=(0.,:mm))
    plot!(p1[2]; xformatter=:none, yformatter=:none,bottom_margin=(-3.5,:mm),
        left_margin=(-3.5,:mm))
    plot!(p1[3]; top_margin=(0.,:mm),xlabel=" ",ylabel=" ")
    plot!(p1[4]; yformatter=:none,left_margin=(-3.5,:mm))

    annotate!(p1[3],lx1,3,(L"\sum\Delta t"*" [s]",12,:black,:center))
    annotate!(p1[3],-0.175*lx1,-16,(L"f_{\beta,F}",12,90.,:center,:black))

    display(p1)

    
    lx2 = min(maximum(dist)/1e-3,maxdist)

    p2 = scatter(dist/1e-3,obj/1e3; legend=false,markersize=2,layout=grid(2,2),
        yflip=true)

    xlims!(p2,(0,lx2*1.01)); ylims!(p2,(-15,0.1))

    for s in eachindex(sigx)
        N = size(T,1); nsuccess = sum(T[:,1,s] .<= threshold)
        succ = nsuccess/N; avg = round(Int,mean(T[:,1,s]))

        if s == 4
            annotate!(p2[s],lx2*0.05,-7,
                (
                    L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                    L"\eta="*"$succ\n"*
                    L"\overline{f_{\beta,F}}="*"$avg",
                    8,:black,:left
                ))
        else
            annotate!(p2[s],lx2*0.95,-3,
                (
                    L"\sigma_x="*"$(round(Int,sigx[s]/1e-6)) µm\n"*
                    L"\eta="*"$succ\n"*
                    L"\overline{f_{\beta,F}}="*"$avg",
                    8,:black,:right
                ))
        end
    end

    plot!(p2[1]; xformatter=:none,bottom_margin=(-3.5,:mm),right_margin=(0.,:mm))
    plot!(p2[2]; xformatter=:none, yformatter=:none,bottom_margin=(-3.5,:mm),
        left_margin=(-3.5,:mm))
    plot!(p2[3]; top_margin=(0.,:mm),xlabel=" ",ylabel=" ")
    plot!(p2[4]; yformatter=:none,left_margin=(-3.5,:mm))

    annotate!(p2[3],lx2,3,(L"\sum\Delta X"*" [mm]",12,:center,:black))
    annotate!(p2[3],-0.175*lx2,-16,(L"f_{\beta,F}",12,90.,:center,:black))

    display(p2)

    return p1, p2
end