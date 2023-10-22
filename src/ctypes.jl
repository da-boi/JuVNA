# c types for julia wrapper

import Base.unsafe_convert, Base.cconvert

const __time64_t = Clonglong
const time_t = __time64_t
const long_t = Clonglong
const ulong_t = Culonglong
const result_t = Cint
const device_t = Cint
const device_enumeration_t = Cuint
const logging_callback_t = Ptr{Cvoid}
const pchar = Ptr{Cchar}

# mutable struct controller_name_t
# 	ControllerName::Ptr{Cstring}
# 	CtrlFlags::Cuint

# 	function controller_name_t()
# 		new(
# 			# pointer(Vector{UInt8}(undef,17)),
# 			# Vector{UInt8}(undef,17),
# 			pointer(Base.unsafe_convert(Cstring,Base.cconvert(Cstring," "^17))),
# 			0
# 		)
# 	end
# end

# mutable struct controller_name_t
# 	ControllerName::Ptr{UInt8}
# 	CtrlFlags::Ref{Cuint}
# end

# Base.cconvert(::Type{controller_name_t},x::controller_name_t_j) = (
# 	Base.cconvert(Ptr{UInt8},x.ControllerName),
# 	x.CtrlFlags
# )

# Base.unsafe_convert(::Type{controller_name_t},x::Tuple{Vector{UInt8},Cuint}) = controller_name_t(
# 	Base.unsafe_convert(Ptr{UInt8},x[1]),
# 	Ref{x[2]}
# )

mutable struct calibration_t
    A::Cdouble
    MicrostepMode::Cuint

	function calibration_t()
		new(0,0)
	end
end

mutable struct device_network_information_t
    ipv4::UInt32
    nodename::NTuple{16, Cchar}
    axis_state::UInt32
    locker_username::NTuple{16, Cchar}
    locker_nodename::NTuple{16, Cchar}
    locked_time::time_t
end

mutable struct feedback_settings_t
    IPS::Cuint
    FeedbackType::Cuint
    FeedbackFlags::Cuint
    CountsPerTurn::Cuint
end

mutable struct home_settings_t
    FastHome::Cuint
    uFastHome::Cuint
    SlowHome::Cuint
    uSlowHome::Cuint
    HomeDelta::Cint
    uHomeDelta::Cint
    HomeFlags::Cuint
end

mutable struct home_settings_calb_t
    FastHome::Cfloat
    SlowHome::Cfloat
    HomeDelta::Cfloat
    HomeFlags::Cuint
end

mutable struct move_settings_t
    Speed::Cuint
    uSpeed::Cuint
    Accel::Cuint
    Decel::Cuint
    AntiplaySpeed::Cuint
    uAntiplaySpeed::Cuint
    MoveFlags::Cuint

	function move_settings_t()
		new([0 for _ in fieldnames(move_settings_t)]...)
	end
end

mutable struct move_settings_calb_t
    Speed::Cfloat
    Accel::Cfloat
    Decel::Cfloat
    AntiplaySpeed::Cfloat
    MoveFlags::Cuint
end

mutable struct engine_settings_t
    NomVoltage::Cuint
    NomCurrent::Cuint
    NomSpeed::Cuint
    uNomSpeed::Cuint
    EngineFlags::Cuint
    Antiplay::Cint
    MicrostepMode::Cuint
    StepsPerRev::Cuint

	function engine_settings_t()
		new([0 for _ in fieldnames(engine_settings_t)]...)
	end
end

mutable struct engine_settings_calb_t
    NomVoltage::Cuint
    NomCurrent::Cuint
    NomSpeed::Cfloat
    EngineFlags::Cuint
    Antiplay::Cfloat
    MicrostepMode::Cuint
    StepsPerRev::Cuint

	function engine_settings_calb_t()
		new([0 for _ in fieldnames(engine_settings_calb_t)]...)
	end
end

mutable struct entype_settings_t
    EngineType::Cuint
    DriverType::Cuint
end

mutable struct power_settings_t
    HoldCurrent::Cuint
    CurrReductDelay::Cuint
    PowerOffDelay::Cuint
    CurrentSetTime::Cuint
    PowerFlags::Cuint
end

mutable struct secure_settings_t
    LowUpwrOff::Cuint
    CriticalIpwr::Cuint
    CriticalUpwr::Cuint
    CriticalT::Cuint
    CriticalIusb::Cuint
    CriticalUusb::Cuint
    MinimumUusb::Cuint
    Flags::Cuint
end

mutable struct edges_settings_t
    BorderFlags::Cuint
    EnderFlags::Cuint
    LeftBorder::Cint
    uLeftBorder::Cint
    RightBorder::Cint
    uRightBorder::Cint
end

mutable struct edges_settings_calb_t
    BorderFlags::Cuint
    EnderFlags::Cuint
    LeftBorder::Cfloat
    RightBorder::Cfloat
end

mutable struct pid_settings_t
    KpU::Cuint
    KiU::Cuint
    KdU::Cuint
    Kpf::Cfloat
    Kif::Cfloat
    Kdf::Cfloat
end

mutable struct sync_in_settings_t
    SyncInFlags::Cuint
    ClutterTime::Cuint
    Position::Cint
    uPosition::Cint
    Speed::Cuint
    uSpeed::Cuint
end

mutable struct sync_in_settings_calb_t
    SyncInFlags::Cuint
    ClutterTime::Cuint
    Position::Cfloat
    Speed::Cfloat
end

mutable struct sync_out_settings_t
    SyncOutFlags::Cuint
    SyncOutPulseSteps::Cuint
    SyncOutPeriod::Cuint
    Accuracy::Cuint
    uAccuracy::Cuint
end

mutable struct sync_out_settings_calb_t
    SyncOutFlags::Cuint
    SyncOutPulseSteps::Cuint
    SyncOutPeriod::Cuint
    Accuracy::Cfloat
end

mutable struct extio_settings_t
    EXTIOSetupFlags::Cuint
    EXTIOModeFlags::Cuint
end

mutable struct brake_settings_t
    t1::Cuint
    t2::Cuint
    t3::Cuint
    t4::Cuint
    BrakeFlags::Cuint
end

mutable struct control_settings_t
    MaxSpeed::NTuple{10, Cuint}
    uMaxSpeed::NTuple{10, Cuint}
    Timeout::NTuple{9, Cuint}
    MaxClickTime::Cuint
    Flags::Cuint
    DeltaPosition::Cint
    uDeltaPosition::Cint
end

mutable struct control_settings_calb_t
    MaxSpeed::NTuple{10, Cfloat}
    Timeout::NTuple{9, Cuint}
    MaxClickTime::Cuint
    Flags::Cuint
    DeltaPosition::Cfloat
end

mutable struct joystick_settings_t
    JoyLowEnd::Cuint
    JoyCenter::Cuint
    JoyHighEnd::Cuint
    ExpFactor::Cuint
    DeadZone::Cuint
    JoyFlags::Cuint
end

mutable struct ctp_settings_t
    CTPMinError::Cuint
    CTPFlags::Cuint
end

mutable struct uart_settings_t
    Speed::Cuint
    UARTSetupFlags::Cuint
end

mutable struct calibration_settings_t
    CSS1_A::Cfloat
    CSS1_B::Cfloat
    CSS2_A::Cfloat
    CSS2_B::Cfloat
    FullCurrent_A::Cfloat
    FullCurrent_B::Cfloat
end

mutable struct controller_name_t
    ControllerName::NTuple{17, Cchar}
    CtrlFlags::Cuint

    function controller_name_t()
        new(ntuple(_->Cchar(0),17),0)
    end
end

mutable struct nonvolatile_memory_t
    UserData::NTuple{7, Cuint}
end

mutable struct emf_settings_t
    L::Cfloat
    R::Cfloat
    Km::Cfloat
    BackEMFFlags::Cuint
end

mutable struct engine_advansed_setup_t
    stepcloseloop_Kw::Cuint
    stepcloseloop_Kp_low::Cuint
    stepcloseloop_Kp_high::Cuint
end

mutable struct extended_settings_t
    Param1::Cuint
end

mutable struct get_position_t
    Position::Cint
    uPosition::Cint
    EncPosition::long_t
	
	function get_position_t()
		new(0,0,0)
	end

    function get_position_t(pos::Cint,upos::Cint)
        new(pos,upos,0)
    end
end

mutable struct get_position_calb_t
    Position::Cfloat
    EncPosition::long_t
end

mutable struct set_position_t
    Position::Cint
    uPosition::Cint
    EncPosition::long_t
    PosFlags::Cuint
end

mutable struct set_position_calb_t
    Position::Cfloat
    EncPosition::long_t
    PosFlags::Cuint
end

mutable struct status_t
    MoveSts::Cuint
    MvCmdSts::Cuint
    PWRSts::Cuint
    EncSts::Cuint
    WindSts::Cuint
    CurPosition::Cint
    uCurPosition::Cint
    EncPosition::long_t
    CurSpeed::Cint
    uCurSpeed::Cint
    Ipwr::Cint
    Upwr::Cint
    Iusb::Cint
    Uusb::Cint
    CurT::Cint
    Flags::Cuint
    GPIOFlags::Cuint
    CmdBufFreeSpace::Cuint

	function status_t()
		new([0 for _ in fieldnames(status_t)]...)
	end
end

mutable struct status_calb_t
    MoveSts::Cuint
    MvCmdSts::Cuint
    PWRSts::Cuint
    EncSts::Cuint
    WindSts::Cuint
    CurPosition::Cfloat
    EncPosition::long_t
    CurSpeed::Cfloat
    Ipwr::Cint
    Upwr::Cint
    Iusb::Cint
    Uusb::Cint
    CurT::Cint
    Flags::Cuint
    GPIOFlags::Cuint
    CmdBufFreeSpace::Cuint
end

mutable struct measurements_t
    Speed::NTuple{25, Cint}
    Error::NTuple{25, Cint}
    Length::Cuint
end

mutable struct chart_data_t
    WindingVoltageA::Cint
    WindingVoltageB::Cint
    WindingVoltageC::Cint
    WindingCurrentA::Cint
    WindingCurrentB::Cint
    WindingCurrentC::Cint
    Pot::Cuint
    Joy::Cuint
    DutyCycle::Cint
end

mutable struct device_information_t
    Manufacturer::NTuple{5, Cchar}
    ManufacturerId::NTuple{3, Cchar}
    ProductDescription::NTuple{9, Cchar}
    Major::Cuint
    Minor::Cuint
    Release::Cuint

	function device_information_t()
		new(
			NTuple{5,Cchar}((0,0,0,0,0)),
			NTuple{3,Cchar}((0,0,0)),
			NTuple{9,Cchar}((0,0,0,0,0,0,0,0,0)),
			0,0,0
		)
	end
end

mutable struct serial_number_t
    SN::Cuint
    Key::NTuple{32, UInt8}
    Major::Cuint
    Minor::Cuint
    Release::Cuint
end

mutable struct analog_data_t
    A1Voltage_ADC::Cuint
    A2Voltage_ADC::Cuint
    B1Voltage_ADC::Cuint
    B2Voltage_ADC::Cuint
    SupVoltage_ADC::Cuint
    ACurrent_ADC::Cuint
    BCurrent_ADC::Cuint
    FullCurrent_ADC::Cuint
    Temp_ADC::Cuint
    Joy_ADC::Cuint
    Pot_ADC::Cuint
    L5_ADC::Cuint
    H5_ADC::Cuint
    A1Voltage::Cint
    A2Voltage::Cint
    B1Voltage::Cint
    B2Voltage::Cint
    SupVoltage::Cint
    ACurrent::Cint
    BCurrent::Cint
    FullCurrent::Cint
    Temp::Cint
    Joy::Cint
    Pot::Cint
    L5::Cint
    H5::Cint
    deprecated::Cuint
    R::Cint
    L::Cint
end

mutable struct debug_read_t
    DebugData::NTuple{128, UInt8}
end

mutable struct debug_write_t
    DebugData::NTuple{128, UInt8}
end

mutable struct stage_name_t
    PositionerName::NTuple{17, Cchar}

    function stage_name_t()
        new(ntuple(_->Cchar(0),17))
    end
end

mutable struct stage_information_t
    Manufacturer::NTuple{17, Cchar}
    PartNumber::NTuple{25, Cchar}

    function stage_information_t()
        new(
            ntuple(_->Cchar(0),17),
            ntuple(_->Cchar(0),25)
        )
    end
end

mutable struct stage_settings_t
    LeadScrewPitch::Cfloat
    Units::NTuple{9, Cchar}
    MaxSpeed::Cfloat
    TravelRange::Cfloat
    SupplyVoltageMin::Cfloat
    SupplyVoltageMax::Cfloat
    MaxCurrentConsumption::Cfloat
    HorizontalLoadCapacity::Cfloat
    VerticalLoadCapacity::Cfloat
end

mutable struct motor_information_t
    Manufacturer::NTuple{17, Cchar}
    PartNumber::NTuple{25, Cchar}
end

mutable struct motor_settings_t
    MotorType::Cuint
    ReservedField::Cuint
    Poles::Cuint
    Phases::Cuint
    NominalVoltage::Cfloat
    NominalCurrent::Cfloat
    NominalSpeed::Cfloat
    NominalTorque::Cfloat
    NominalPower::Cfloat
    WindingResistance::Cfloat
    WindingInductance::Cfloat
    RotorInertia::Cfloat
    StallTorque::Cfloat
    DetentTorque::Cfloat
    TorqueConstant::Cfloat
    SpeedConstant::Cfloat
    SpeedTorqueGradient::Cfloat
    MechanicalTimeConstant::Cfloat
    MaxSpeed::Cfloat
    MaxCurrent::Cfloat
    MaxCurrentTime::Cfloat
    NoLoadCurrent::Cfloat
    NoLoadSpeed::Cfloat
end

mutable struct encoder_information_t
    Manufacturer::NTuple{17, Cchar}
    PartNumber::NTuple{25, Cchar}
end

mutable struct encoder_settings_t
    MaxOperatingFrequency::Cfloat
    SupplyVoltageMin::Cfloat
    SupplyVoltageMax::Cfloat
    MaxCurrentConsumption::Cfloat
    PPR::Cuint
    EncoderSettings::Cuint
end

mutable struct hallsensor_information_t
    Manufacturer::NTuple{17, Cchar}
    PartNumber::NTuple{25, Cchar}
end

mutable struct hallsensor_settings_t
    MaxOperatingFrequency::Cfloat
    SupplyVoltageMin::Cfloat
    SupplyVoltageMax::Cfloat
    MaxCurrentConsumption::Cfloat
    PPR::Cuint
end

mutable struct gear_information_t
    Manufacturer::NTuple{17, Cchar}
    PartNumber::NTuple{25, Cchar}
end

mutable struct gear_settings_t
    ReductionIn::Cfloat
    ReductionOut::Cfloat
    RatedInputTorque::Cfloat
    RatedInputSpeed::Cfloat
    MaxOutputBacklash::Cfloat
    InputInertia::Cfloat
    Efficiency::Cfloat
end

mutable struct accessories_settings_t
    MagneticBrakeInfo::NTuple{25, Cchar}
    MBRatedVoltage::Cfloat
    MBRatedCurrent::Cfloat
    MBTorque::Cfloat
    MBSettings::Cuint
    TemperatureSensorInfo::NTuple{25, Cchar}
    TSMin::Cfloat
    TSMax::Cfloat
    TSGrad::Cfloat
    TSSettings::Cuint
    LimitSwitchesSettings::Cuint
end

mutable struct init_random_t
    key::NTuple{16, UInt8}
end

mutable struct globally_unique_identifier_t
    UniqueID0::Cuint
    UniqueID1::Cuint
    UniqueID2::Cuint
    UniqueID3::Cuint
end

