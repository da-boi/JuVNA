using JLD2, Dates
using Plots: savefig

function getDateString()
    d = now()

    return "$(Day(d).value)_$(Month(d).value)_$(Year(d).value)-$(Hour(d).value)_$(Minute(d).value)"
end

function saveScan(folderpath::String,scanplot)
    savefig(scanplot,joinpath(folderpath,"scans",getDateString()*".pdf"))
end

function saveStuff(folderpath::String,ref0,histscan,R,freqs)
    jldsave(joinpath(folderpath,"scans",getDateString()*".jld2"); ref0,histscan,R,freqs)
end

function saveStuff(folderpath::String,optimizer::String,scan,ref0,hist,trace,freqs; p0=[0.013,0.027])
    d = getDateString()

    ph = plotPath(scan,hist,p0)
    pt = plotPath(scan,trace,p0)

    objf = round(Int,trace[end].obj)

    pa = analyse(hist,trace,freqs)

    jldsave(joinpath(folderpath,"optims",optimizer*"_"*objf*"_"*d*".jld2"); ref0,hist,trace,freqs)
    savefig(ph,joinpath(folderpath,"optims",optimizer*"_hist_"*objf*"_"*d*".pdf"))
    savefig(pt,joinpath(folderpath,"optims",optimizer*"_trace_"*objf*"_"*d*".pdf"))

    savefig(pa,joinpath(folderpath,"optims",optimizer*"_hist_"*objf*"_"*d*".pdf"))
end





# setSweepPoints(vna,128)
# send(vna, "FORMat:DATA REAL,64\n") # Set the return type to a 64 bit Float
# send(vna, "FORMat:BORDer SWAPPed;*OPC?\n") # Swap the byte order and wait for the completion of the commands
# send(vna, "SENSe:AVERage:STATe ON;*OPC?\n")
# send(vna, "SENSe:AVERage:STATe OFF;*OPC?\n")
# send(vna, "SENSe:AVERage:COUNt 10;*OPC\n")
# send(vna, "SENS:SWE:GRO:COUN 20;*OPC?\n")

# getTrace(vna; set=true)

# getTraceG(vna,10; set=true)
