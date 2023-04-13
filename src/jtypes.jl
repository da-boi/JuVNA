# type aliases for julia syntaxing

const DeviceId = device_t
const DeviceEnumeration = device_enumeration_t
const Calibration = calibration_t
const DeviceInfo = device_information_t
const Status = status_t
const Position = get_position_t
const Position(pos::Integer,upos::Integer) = Position(Cint(pos),Cint(upos))
const Position(pos::Real,upos::Real) = Position(Cint(pos),Cint(upos))
const MoveSettings = move_settings_t
const EngineSettings = engine_settings_t
const EngineSettingsCalb = engine_settings_calb_t
const ControllerName  = controller_name_t
const StageName = stage_name_t
const StageInfo = stage_information_t
