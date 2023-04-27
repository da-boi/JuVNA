# functionality for using and controlling the keysight VNA
# with pure julia

# local 134.61.159.83 (RWTH ws3amadmax03)
# host (vna) 134.61.12.182
# port at host 5025

using Sockets
import Sockets.send, Sockets.TCPSocket


function send(socket::TCPSocket,msg::String)
    write(socket,codeunits(msg))
end

function recv(socket::TCPSocket)
    refreshBuffer(socket)
    return readavailable(socket)
end

function recv(socket::TCPSocket,nb::Integer)
    refreshBuffer(socket)
    return read(socket,nb)
end

function async_reader(io::IO, timeout_sec)::Channel
    ch = Channel(1)
    task = @async begin
        reader_task = current_task()

        function timeout_cb(timer)
            put!(ch, :timeout)
            Base.throwto(reader_task, InterruptException())
        end

        timeout = Timer(timeout_cb, timeout_sec)
        data = String(readavailable(io))
        timeout_sec > 0 && close(timeout) # Cancel the timeout
        put!(ch, data)
    end

    bind(ch, task)

    return ch
end

# ch_out = async_reader(io, timeout)
# out = take!(ch_out)  # if out===:timeout, a timeout occurred

function getBufferSize(socket::TCPSocket)
    return socket.buffer.size
    # return getfield(socket,:buffer).size
end

function refreshBuffer(socket::TCPSocket)
    @async eof(socket)

    return
end

function isBlocked(socket::TCPSocket)
    refreshBuffer(socket)

    return getBufferSize(socket) == 0
end






function connectVNA(; host=ip"134.61.12.182",port=5025)
    try
        socket = connect(host,port)

        refreshBuffer(socket)

        return socket
    catch e
        error("Failed to connect to host.\n"*e.msg)

        return nothing
    end
end

function disconnectVNA(socket::TCPSocket)
    close(socket)
end

function identifyVNA(socket::TCPSocket)
    send(socket,"*IDN?\n")
end

function clearStatus(socket::TCPSocket)
    send(socket,"*CLS\n")
end





function setPowerLevel(socket::TCPSocket,power::Integer)
    if power > 5
        error("Power threshold reached. Must be less than 5 dBm.")
    end

    write(socket,
        codeunits(
            "SOURce:POWer:LEVel:IMMediate:AMPLitude "*string(power)*"\n"
        )
    )
end

function setCalibration(socket::TCPSocket,calName::String)
    write(socket,
        codeunits(
            "SENSe:CORRection:CSET:ACTivate \""*string(calName)*"\",1\n"
        )
    )

    return
end

function setAveraging(socket::TCPSocket,state::Bool; counts::Int=50)
    if counts <= 0
        error("Count number must be positive.")
    end

    write(socket,
        codeunits(
            "SENSe:AVERage:STATe "*(state ? "ON\n" : "OFF\n")
        )
    )

    if !state
        return
    end 

    write(socket,
        codeunits(
            "SENSe:AVERage:COUNt "*string(counts)*"\n"
        )
    )
end

function setFrequencies(socket::TCPSocket,center::Float64,span::Float64)
    if !(10e6 <= center <= 43.5e9)
        error("Center frequency must be between 10 MHz and 43.5 GHz.")
    elseif !(0 <= span <= min(abs(center-10e6),abs(center-43.5)))
        error("Span reaches out of 10 MHz to 43.5 GHz bandwidth.")
    end

    write(socket,
        codeunits(
            "SENS:FREQ:CENTer "*string(center)*";SPAN "*string(span)*"\n"
        )
    )

    return
end

function setSweepPoints(socket::TCPSocket, points::Integer)
    if points <= 0
        error("Must use at least one sweep point.")
    end

    write(socket,
        codeunits(
            "SENSe1:SWEep:POINts "*string(points)*"\n"
        )
    )
end

function setIFBandwidth(socket::TCPSocket, bandwidth::Integer)
    if bandwidth <= 0
        error("Resolution must be greater that 0.")
    end

    write(socket,
        codeunits(
            "SENSe1:BANDwidth:RESolution "*string(bandwidth)*"\n"
        )
    )

    return
end

function setMeasurement(socket::TCPSocket, name::String)
    write(socket,
        codeunits(
            "CALCulate:PARameter:SELect '"*name*"'\n"
        )
    )
end

function setFormat2Log(socket::TCPSocket)
    write(socket,
        codeunits(
            "CALCulate:MEASure:FORMat MLOGarithmic\n"
        )
    )

    return
end

function triggerContinuous(socket::TCPSocket)
    write(socket,
        codeunits(
            "sense:sweep:mode hold\n"
        )
    )

    return
end

function triggerHold(socket::TCPSocket)
    write(socket,
        codeunits(
            "sense:sweep:mode continuous\n"
        )
    )
end

function triggerSingleWithHold(socket::TCPSocket)
    write(socket,
        codeunits(
            "SENse:SWEep:MODE SINGle;*OPC?\n"
        )
    )

    recv(socket,8)

    write(socket,
        codeunits(
            "DISPlay:WINDow1:TRACe1:Y:SCALe:AUTO;*OPC?\n"
        )
    )

    return recv(socket,8)
end

function triggerFreeRun(socket::TCPSocket)
    write(socket,
        codeunits(
            "SENse:SWEep:MODE CONT;*OPC?\n"
        )
    )

    return recv(socket,8)
end

function saveS2P(socket::TCPSocket,fileURL::String)
    write(socket,
        codeunits(
            "MMEMory:STORe "*string(fileURL)*"\n"
        )
    )
end

Core.Int(data::Array{UInt8}) = parse(Int, String(data))

function getDataAsBinBlockTransfer(socket::TCPSocket; waittime=0)
    try
        send(socket,"FORMat:DATA REAL,64\n") # Set the return type to a 64 bit Float
        send(socket,"FORMat:BORDer SWAPPed;*OPC?\n") # Swap the byte order and wait for the completion of the commands
        send(socket,"SENSe:SWEep:SPEed FAST\n")  # Set the sweep speed to fast
        send(socket,"SENSe:SWEep:MODE SINGLe;*OPC?\n")  # Set the trigger to Single and wait for completion
        send(socket,"CALCulate:DATA? FDATA\n") # Read the S11 parameter Data
        # Returns
        # 1 Byte: Block Data Delimiter '#'
        # 1 Byte: n := number of nigits for the Number of data bytes in ASCII (between 1 and 9)
        # n Bytes: N := number of data bytes to read in ASCII
        # N Bytes: data
        # 1 Byte: End of line character 0x0A to indicate the end of the data block

        # Wait for the Block Data Delimiter '#'
        while recv(socket,1)[begin] != 0x23 end

        numofdigitstoread = Int(recv(socket,1))

        numofbytes = Int(recv(socket, numofdigitstoread))

        bytes = recv(socket, numofbytes)

        data = reinterpret(Float64, bytes)

        hanginglinefeed = recv(socket,1)
        if hanginglinefeed[begin] != 0x0A
            error("End of Line Character expected to indicate end of data block")
        end

        sleep(waittime)

        send(socket,"FORMat:DATA ASCii,0;*OPC?\n") # Set the return type back to ASCII

        return data
    catch e
        println(e)
        error("Oepsie woepsie, something wrong uwu.")
    end
end

function getFreqAsBinBlockTransfer(socket::TCPSocket; waittime=0)
    try
        send(socket,"CALCulate:PARameter:SELect 'CH1_S11_1'\n") # Select the Channel and Measurement Parameter S11
        send(socket,"FORMat:DATA REAL,64\n") # Set the return type to a 64 bit Float
        send(socket,"FORMat:BORDer SWAPPed;*OPC?\n") # Swap the byte order and wait for the completion of the commands
        send(socket,"CALCulate:X:VALues?\n") # Read the frequency points
        # Returns
        # 1 Byte: Block Data Delimiter '#'
        # 1 Byte: n := number of nigits for the Number of data bytes in ASCII (between 1 and 9)
        # n Bytes: N := number of data bytes to read in ASCII
        # N Bytes: data
        # 1 Byte: End of line character 0x0A to indicate the end of the data block

        # Wait for the Block Data Delimiter '#'
        while recv(socket,1)[begin] != 0x23 end

        numofdigitstoread = Int(recv(socket,1))

        numofbytes = Int(recv(socket, numofdigitstoread))

        bytes = recv(socket, numofbytes)

        data = reinterpret(Float64, bytes)

        hanginglinefeed = recv(socket,1)
        if hanginglinefeed[begin] != 0x0A
            error("End of Line Character expected to indicate end of data block")
        end

        sleep(waittime)

        send(socket,"FORMat:DATA ASCii,0;*OPC?\n") # Set the return type back to ASCII

        return data
    catch e
        println(e)
        error("Oepsie woepsie, something wrong uwu.")
    end
end


# combined functions for convenience

function instrumentErrCheck(socket::TCPSocket)
    try
        erroutclear = false
        noerrresult = codeunits("NO ERROR")

        i = 0

        while !erroutclear
            i += 1

            write(socket,
                codeunits(
                    "SYST:ERR?\n"
                )
            )

            errqueryresults = take!(socket)

            print("Error query results = "*string(Char.(errqueryresults)...))

            erroutclear = occursin(noerrresult,uppercase(errqueryresults))

            if i == 100
                println("Error check timeout.")
                break
            end
        end
    catch e
        println("Send failed.")
        close(socket)
    end
end

function instrumentSimplifiedSetup(socket::TCPSocket;
        calName::String = cals[:c3GHz],
        power::Int = -20,
        center::Float64 = 20.025e9,
        span::Float64 = 50e6,
        sweeppoints::Int = 101,
        ifbandwidth::Int = Int(5e6),
        measurement::String = "CH1_S11_1"
    )

    setCalibration(socket,calName)
    setPowerLevel(socket,power)
    setAveraging(socket,false)
    setFrequencies(socket,center,span)
    setSweepPoints(socket,sweeppoints)
    setIFBandwidth(socket,ifbandwidth)
    setFormat2Log(socket)
    setMeasurement(socket, measurement)
end

cals = Dict{Symbol,String}(
    :c3GHz => "{AAE0FD65-EEA1-4D1A-95EE-06B3FFCB32B7}",
    :c300MHz => "{AC488992-4AB2-4EB5-9D23-34EF8774902F}"
)
