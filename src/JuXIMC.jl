# Load library


# module JuXIMC

export infoXIMC, setupDevices, 
    openDevice, openDevices, closeDevice, closeDevices, checkOrdering, 
    commandMove, commandWaitForStop, 
    getPos, getPosition

using StringViews
using Printf

include("cenums.jl")
include("ctypes.jl")
include("jtypes.jl")
include("libximc_api.jl")
include("utilities.jl")

setBindyKey(joinpath("win64","keyfile.sqlite"))

# setBindyKey(joinpath(dirname(@__DIR__),"XIMC\\ximc-2.13.6\\ximc\\win64\\keyfile.sqlite"))

function getDeviceInformation(device::DeviceId)
    deviceinfo = device_information_t()

    result = get_device_information(device,deviceinfo)

    if result != 0
        error("Result error: $result")
    end

    return deviceinfo
end

function getStageName(device::DeviceId; returnstruct::Bool=false)
    name = stage_name_t()

    result = get_stage_name(device,name)

    if result != 0
        error("Result error: $result")
    end

    if returnstruct
        return result, name
    end

    return String(name.PositionerName)
end

function getStageNameEnumerate(devenum::Ptr{DeviceEnumeration},idx::Integer)
    name = stage_name_t()

    result = get_enumerate_device_stage_name(devenum,idx-1,name)

    if result != 0
        error("Result error: $result")
    end

    return name
end

function getStageInformation(device::DeviceId)
    stageinfo = stage_information_t()

    result = get_stage_information(device,stageinfo)

    if result != 0
        error("Result error: $result")
    end

    return stageinfo
end

function getStatus(device::DeviceId)
    status = status_t()

    result = get_status(device,status)

    if result != 0
        error("Result error: $result")
    end

    return status
end

function getStatus!(status::Status,device::DeviceId)
    result = get_status(device,status)

    if result != 0
        error("Result error: $result")
    end
end

function getPosition(device::DeviceId)
    pos = get_position_t()

    result = get_position(device,pos)

    if result != 0
        error("Result error: $result")
    end

    return pos
end

function getPosition!(pos::Position,device::DeviceId)
    result = get_position(device,pos)

    if result != 0
        error("Result error: $result")
    end
end

const getPos! = getPosition!
const getPos = getPosition

function getPosition(devices::Vector{DeviceId}; fmt::Type=Matrix)   # fmt = Vector or Matrix
    if fmt == Matrix
        P = Matrix{Int64}(undef,length(devices),3)
    elseif fmt == Vector
        P = Vector{Tuple{Int,Int}}(undef,length(devices))
    else
        error("Unsupported output format.")
    end

    for i in eachindex(devices)
        p = getPosition(devices[i])
        if fmt == Matrix
            P[i,1] = copy(p.Position)
            P[i,2] = copy(p.uPosition)
            P[i,3] = copy(p.EncPosition)
        elseif fmt == Vector
            P[i] = (p.Position,p.uPosition)
        end
    end

    return P
end

function getPosition(devices::DeviceId...; fmt::Type=Matrix)
    if fmt == Matrix
        P = Matrix{Int64}(undef,length(devices),3)
    elseif fmt == Vector
        P = Vector{Position}(undef,length(devices))
    else
        error("Unsupported output format.")
    end

    for i in eachindex(devices)
        p = getPosition(devices[i])
        if fmt == Matrix
            P[i,1] = copy(p.Position)
            P[i,2] = copy(p.uPosition)
            P[i,3] = copy(p.EncPosition)
        elseif fmt == Vector
            P[i] = copy(p)
        end
    end

    return P
end

function getPosition(devices::Vector{DeviceId},
        cal::Dict{String,Tuple{Symbol,Float64}};
        outputunit=:m)
    P = Vector{Float64}(undef,length(devices))

    for i in eachindex(devices)
        p = getPosition(devices[i])
        P[i] = steps2x(p.Position,p.uPosition; outputunit=outputunit,
            cal=cal[getStageName(devices[i])])
    end

    return P
end

function isSamePosition(x::Position, y::Position)
    return (x.Position == y.Position) && (x.uPosition == y.uPosition)
end

function isGreaterEqPosition(x::Position, y::Position)
    return (x.Position > y.Position) || ((x.Position == y.Position) && (x.uPosition >= y.uPosition))
end

function isSmallerEqPosition(x::Position, y::Position)
    return (x.Position < y.Position) || ((x.Position == y.Position) && (x.uPosition <= y.uPosition))
end


function isGreaterPosition(x::Position, y::Position)
    return (x.Position > y.Position) || ((x.Position == y.Position) && (x.uPosition > y.uPosition))
end

function commandLeft(device::DeviceId; info=false)
    info && println("\nMoving left")

    result = command_left(device)

    info && println("\nResult: "*StringView(result))

    return result
end

function commandMove(device::DeviceId,pos::Int32,upos::Int32; info=false)
    info && println("\nGoing to $pos, $upos")

    result = command_move(device,pos,upos)

    info && println("\nResult: $result")

    return result
end

const commandMove(device::DeviceId,pos::Real,upos::Real) = commandMove(device,Int32(pos),Int32(upos))

function commandMove(device::DeviceId,pos::Position; info=false)
    info && println("\nGoing to $pos, $upos")

    result = command_move(device,pos.Position,pos.uPosition)

    info && println("\nResult: $result")

    return result
end

function commandMove(devices::Vector{DeviceId},positions::Vector{Tuple{Int,Int}})
    if length(devices) != length(positions)
        error("Device number and position number don't match.")
    end
    
    for i in eachindex(devices)
        commandMove(devices[i],positions[i][1],positions[i][2])
    end
end

function commandMove(devices::Vector{DeviceId},positions::Matrix{Int32}; info=false)
    if size(positions,1) != length(devices) || size(positions,2) != 2
        error("Dimension mismatch: ndevices x 2 required.")
    end

    for i in 1:size(positions,1)
        commandMove(devices[i],positions[i,1],positions[i,2])
    end
end

function commandMove(device::DeviceId,x::Real,cal::Dict{String,Tuple{Symbol,Float64}}; info=false,inputunit=:mm)
    p = x2steps(x; inputunit=inputunit,cal=cal[getStageName(device)])

    info && println("\n Going to $x$inputunit = $(p[1]), $(p[2])")

    result = command_move(device,p[1],p[2])

    info && println("\nResult: $result")

    return result
end

function commandMove(devices::Vector{DeviceId},x::Vector{<:Real},cal::Dict{String,Tuple{Symbol,Float64}}; info=false,inputunit=:mm)
    if length(devices) != length(x)
        error("Amount of values don't match.")
    end

    for i in eachindex(devices)
        p = x2steps(x[i]; inputunit=inputunit,cal=cal[getStageName(devices[i])])

        info && println("\n D$i going to $x$inputunit = $(p[1]), $(p[2])")

        command_move(devices[i],p[1],p[2])
    end
end





function commandWaitForStop(device::DeviceId; interval::UInt32=0x00000a,info::Bool=false)
    # info && println("\nWaiting for stop")

    result = command_wait_for_stop(device,interval)

    # info && println("\nResult: "*StringView(result))

    # return result
end

function commandWaitForStop(devices::Vector{DeviceId}; interval::UInt32=0x00000a,info::Bool=false)
    for i in eachindex(devices)
        commandWaitForStop(devices[i]; interval=interval,info=info)
    end
end

function enumerateDevices(flags,hints::Union{Base.CodeUnits{UInt8, String},String})
    hints = Vector{UInt8}(hints)

    enum = enumerate_devices(flags,hints)

    return enum
end

function getControllerName(device::DeviceId)
    controller = controller_name_t()

    result = get_controller_name(device,controller)

    if result != 0
        error("Result error: $result")
    end

    return controller
end

function getEnumerateDeviceControllerName(devenum::Ptr{DeviceEnumeration},ind::Int32)
    controller = controller_name_t()

    result = get_enumerate_device_controller_name(devenum,ind-1,controller)

    if result != 0
        error("Result error: $result")
    end

    return controller
end

const getEnumerateDeviceControllerName(devenum::Ptr{DeviceEnumeration},ind::Real) = getEnumerateDeviceControllerName(devenum,Int32(ind))

function getDeviceCount(devenum::Ptr{DeviceEnumeration}; info=false)
    count = get_device_count(devenum)

    info && println("Device count: $count")

    return count
end

function getDeviceName(devenum::Ptr{DeviceEnumeration},ind::Integer)
    get_device_name(devenum,ind-1)
end

function openDevice(uri)
    open_device(uri)
end

function openDevices(enumnames::Vector{Cstring},stagenames::Dict{String,Int})
    if length(enumnames) < 1
        error("No devices to open!")
    end

    D = [openDevice(en) for en in enumnames]

    S = [String(getStageName(d)) for d in D]

    return D[sortperm([get(stagenames,s,0) for s in S])]
end

function checkOrdering(devices::Vector{DeviceId},stagenames::Dict{String,Int})
    # if length(devices) != length(stagenames)
    #     error("Unequal amounts of values.")
    # end

    @printf "%3s | %-17s\n" "D" "Stage names"
    for i in eachindex(devices)
        @printf "%3.0f | %-17s\n" i getStageName(devices[i])

        if stagenames[getStageName(devices[i])] != i
            error("Names did not match with ordering.")
        end
    end
end

function closeDevice(device::DeviceId)
    close_device(device)
end

function closeDevice(args::DeviceId...)
    for arg in args
        close_device(arg)
    end
end

const closeDevices(args::DeviceId...) = closeDevice(args...)
const closeDevices(devices::Vector{DeviceId}) = closeDevice.(devices)

function serialNumber(device::DeviceId)
    error("Not working yet.")

    serial = Ref(Cuint(0))

    result = get_serial_number(device,serial)

    if result != 0
        error("Result error: $result")
    end

    return serial
end

function getMoveSettings(device::DeviceId)
    mvst = move_settings_t()

    result = get_move_settings(device,Ref(mvst))

    if result != 0
        error("Result error: $result")
    end

    return mvst
end

function getSpeed(device::DeviceId)
    mvst = move_settings_t()

    result = get_move_settings(device,Ref(mvst))

    if result != 0
        error("Result error: $result")
    end

    return (mvst.Speed, mvst.uSpeed)
end

function resetMoveSettings(device::DeviceId)
    mvst = move_settings_t()

    result = get_move_settings(device,Ref(mvst))

    if result != 0
        error("Result error: $result")
    end

    return mvst
end

function setMoveSettings(device::DeviceId,mvst::MoveSettings)
    result = set_move_settings(device,Ref(mvst))

    return result
end

function setSpeed(device::DeviceId,speed::Integer; info=false)
    info && println("\nSet speed")

    mvst = getMoveSettings(device)

    info && println("Original speed: "*string(mvst.Speed))

    mvst.Speed = speed

    result = setMoveSettings(device,mvst)

    info && println("Write command result: "*string(result))
end

function getEngineSettings(device::DeviceId)
    eng = engine_settings_t()

    result = get_engine_settings(device,Ref(eng))

    if result != 0
        error("Result error: $result")
    end

    return eng
end

function setEngineSettings(device::DeviceId,eng::EngineSettings)
    result = get_engine_settings(device,Ref(eng))

    return result
end

function setMicroStepMode(device::DeviceId;
        mode::MicrostepMode=MICROSTEP_MODE_FRAC_256,info=false)

    info && println("\nSet microstep mode to $mode")

    _, eng = getEngineSettings(device)

    eng.MicrostepMode = copy(mode)

    result = setEngineSettings(device,eng)

    info && println("Command result: "*String(result))

    return result
end





function msecSleep(msec::UInt32)
    msec_sleep(msec)
end

function infoDevice(device::DeviceId)
    deviceinfo = getDeviceInformation(device)

    println("- Device information for D$device -")
    println("Manufacturer:       "*String(deviceinfo.Manufacturer))
    println("ManufacturerId:     "*String(deviceinfo.ManufacturerId))
    println("ProductDescription: "*String(deviceinfo.ProductDescription))
    println("Major:   ",deviceinfo.Major)
    println("Minor:   ",deviceinfo.Minor)
    println("Release: ",deviceinfo.Release)
end

function infoStage(device::DeviceId)
    stagename = getStageName(device)
    stageinfo = getStageInformation(device)

    println("- Stage information for D$device -")
    println("Stage name:   ",String(stagename.PositionerName))
    println("Manufacturer: ",String(stageinfo.Manufacturer))
    println("Part number:  ",String(stageinfo.PartNumber))
end

function infoStatus(device::DeviceId)
    status = getStatus(device)

    println("- Status information for D$device -")
    println("Status.Ipwr:  " + StringView(status.Ipwr))
    println("Status.Upwr:  " + StringView(status.Upwr))
    println("Status.Iusb:  " + StringView(status.Iusb))
    println("Status.Flags: " + StringView(hex(status.Flags)))
end

function infoPosition(device::DeviceId)
    pos = getPosition(device)

    println("- Position information for D$device -")
    println(" Position: "*StringView(pos.Position))
    println("uPosition: "*StringView(pos.uPosition))
end

function infoSerial(device::DeviceId)
    serial = serialNumber(device)

    println("Serial: "*string(serial))
end

function infoMoveSettings(device::DeviceId)
    mvst = getMoveSettings(device)

    println("- Move setting information for D$device -")
    for field in fieldnames(MoveSettings)
        println("$field: "*String(getfield(mvst,field)))
    end
end

function infoSpeed(device::DeviceId)
    speed = getSpeed(device)

    println("- Speed information for D$device -")
    println(" Speed:"*String(speed[1]))
    println("uSpeed:"*String(speed[2]))
end

function infoXIMC()
    buf = Vector{UInt8}(undef,32)

    ximc_version(buf)

    filter!(x->x!=0x00,buf)

    println("\nXIMC library version: "*StringView(buf))

    return buf
end

function setupDevices(probeflags::UInt32,enumhints::Base.CodeUnits{UInt8,String})
    devenum = enumerateDevices(probeflags,enumhints)
    devcount = getDeviceCount(devenum; info=true)

    if devcount == 0
        println("No devices found.")

        return Nothing,Nothing,Nothing
    end

    enumnames = Array{Cstring}(undef,devcount)

    @printf "%+2s | %-32s | %-8s | %-8s | %-16s\n" "D" "Name" "Serial" "Port" "Stage"

    for i in 1:devcount
        enumname = getDeviceName(devenum,i)
        enumctrlname = getEnumerateDeviceControllerName(devenum,i)
        stagename = getStageNameEnumerate(devenum,i)
        enumnames[i] = enumname

        n = unsafe_string(enumname)
        sn = parse(Int,"0x"*split(n,'/')[end])
        ax = String(enumctrlname.ControllerName)
        stn = String(stagename.PositionerName)

        @printf "%2.0f | %-32s | %-8.0f | %-8s | %-16s\n" i n sn ax stn
    end

    return devcount, devenum, enumnames
end







# end







