



import Base.Libc.Libdl: dlopen, dlclose, dlsym

# function loadDLL()
#     pathximc = joinpath("XIMC","ximc-2.13.6","ximc")

#     if occursin("windows",lowercase(ENV["OS"]))
#         if occursin("64",ENV["PROCESSOR_ARCHITECTURE"])
#             return dlopen(joinpath(pathximc,"win64","libximc"))
#         else
#             return dlopen(joinpath(pathximc,"win32","libximc"))
#         end
#     else
#         error("OS not implemented.")
#     end
# end

# lib = loadDLL()

# const libximc = dlopen(joinpath("XIMC","ximc-2.13.6","ximc","win64","libximc"))
const libximc = dlopen(joinpath("src","win64","libximc"))

function set_feedback_settings(id, feedback_settings)
    ccall((:set_feedback_settings, :libximc), result_t, (device_t, Ptr{feedback_settings_t}), id, feedback_settings)
end

function get_feedback_settings(id, feedback_settings)
    ccall((:get_feedback_settings, :libximc), result_t, (device_t, Ptr{feedback_settings_t}), id, feedback_settings)
end

function set_home_settings(id, home_settings)
    ccall((:set_home_settings, :libximc), result_t, (device_t, Ptr{home_settings_t}), id, home_settings)
end

function set_home_settings_calb(id, home_settings_calb, calibration)
    ccall((:set_home_settings_calb, :libximc), result_t, (device_t, Ptr{home_settings_calb_t}, Ptr{calibration_t}), id, home_settings_calb, calibration)
end

function get_home_settings(id, home_settings)
    ccall((:get_home_settings, :libximc), result_t, (device_t, Ptr{home_settings_t}), id, home_settings)
end

function get_home_settings_calb(id, home_settings_calb, calibration)
    ccall((:get_home_settings_calb, :libximc), result_t, (device_t, Ptr{home_settings_calb_t}, Ptr{calibration_t}), id, home_settings_calb, calibration)
end

function set_move_settings(id, move_settings)
    ccall((:set_move_settings, :libximc), result_t, (device_t, Ptr{move_settings_t}), id, move_settings)
end

function set_move_settings_calb(id, move_settings_calb, calibration)
    ccall((:set_move_settings_calb, :libximc), result_t, (device_t, Ptr{move_settings_calb_t}, Ptr{calibration_t}), id, move_settings_calb, calibration)
end

function get_move_settings(id, move_settings)
    ccall((:get_move_settings, :libximc), result_t, (device_t, Ptr{move_settings_t}), id, move_settings)
end

function get_move_settings_calb(id, move_settings_calb, calibration)
    ccall((:get_move_settings_calb, :libximc), result_t, (device_t, Ptr{move_settings_calb_t}, Ptr{calibration_t}), id, move_settings_calb, calibration)
end

function set_engine_settings(id, engine_settings)
    ccall((:set_engine_settings, :libximc), result_t, (device_t, Ptr{engine_settings_t}), id, engine_settings)
end

function set_engine_settings_calb(id, engine_settings_calb, calibration)
    ccall((:set_engine_settings_calb, :libximc), result_t, (device_t, Ptr{engine_settings_calb_t}, Ptr{calibration_t}), id, engine_settings_calb, calibration)
end

function get_engine_settings(id, engine_settings)
    ccall((:get_engine_settings, :libximc), result_t, (device_t, Ptr{engine_settings_t}), id, engine_settings)
end

function get_engine_settings_calb(id, engine_settings_calb, calibration)
    ccall((:get_engine_settings_calb, :libximc), result_t, (device_t, Ptr{engine_settings_calb_t}, Ptr{calibration_t}), id, engine_settings_calb, calibration)
end

function set_entype_settings(id, entype_settings)
    ccall((:set_entype_settings, :libximc), result_t, (device_t, Ptr{entype_settings_t}), id, entype_settings)
end

function get_entype_settings(id, entype_settings)
    ccall((:get_entype_settings, :libximc), result_t, (device_t, Ptr{entype_settings_t}), id, entype_settings)
end

function set_power_settings(id, power_settings)
    ccall((:set_power_settings, :libximc), result_t, (device_t, Ptr{power_settings_t}), id, power_settings)
end

function get_power_settings(id, power_settings)
    ccall((:get_power_settings, :libximc), result_t, (device_t, Ptr{power_settings_t}), id, power_settings)
end

function set_secure_settings(id, secure_settings)
    ccall((:set_secure_settings, :libximc), result_t, (device_t, Ptr{secure_settings_t}), id, secure_settings)
end

function get_secure_settings(id, secure_settings)
    ccall((:get_secure_settings, :libximc), result_t, (device_t, Ptr{secure_settings_t}), id, secure_settings)
end

function set_edges_settings(id, edges_settings)
    ccall((:set_edges_settings, :libximc), result_t, (device_t, Ptr{edges_settings_t}), id, edges_settings)
end

function set_edges_settings_calb(id, edges_settings_calb, calibration)
    ccall((:set_edges_settings_calb, :libximc), result_t, (device_t, Ptr{edges_settings_calb_t}, Ptr{calibration_t}), id, edges_settings_calb, calibration)
end

function get_edges_settings(id, edges_settings)
    ccall((:get_edges_settings, :libximc), result_t, (device_t, Ptr{edges_settings_t}), id, edges_settings)
end

function get_edges_settings_calb(id, edges_settings_calb, calibration)
    ccall((:get_edges_settings_calb, :libximc), result_t, (device_t, Ptr{edges_settings_calb_t}, Ptr{calibration_t}), id, edges_settings_calb, calibration)
end

function set_pid_settings(id, pid_settings)
    ccall((:set_pid_settings, :libximc), result_t, (device_t, Ptr{pid_settings_t}), id, pid_settings)
end

function get_pid_settings(id, pid_settings)
    ccall((:get_pid_settings, :libximc), result_t, (device_t, Ptr{pid_settings_t}), id, pid_settings)
end

function set_sync_in_settings(id, sync_in_settings)
    ccall((:set_sync_in_settings, :libximc), result_t, (device_t, Ptr{sync_in_settings_t}), id, sync_in_settings)
end

function set_sync_in_settings_calb(id, sync_in_settings_calb, calibration)
    ccall((:set_sync_in_settings_calb, :libximc), result_t, (device_t, Ptr{sync_in_settings_calb_t}, Ptr{calibration_t}), id, sync_in_settings_calb, calibration)
end

function get_sync_in_settings(id, sync_in_settings)
    ccall((:get_sync_in_settings, :libximc), result_t, (device_t, Ptr{sync_in_settings_t}), id, sync_in_settings)
end

function get_sync_in_settings_calb(id, sync_in_settings_calb, calibration)
    ccall((:get_sync_in_settings_calb, :libximc), result_t, (device_t, Ptr{sync_in_settings_calb_t}, Ptr{calibration_t}), id, sync_in_settings_calb, calibration)
end

function set_sync_out_settings(id, sync_out_settings)
    ccall((:set_sync_out_settings, :libximc), result_t, (device_t, Ptr{sync_out_settings_t}), id, sync_out_settings)
end

function set_sync_out_settings_calb(id, sync_out_settings_calb, calibration)
    ccall((:set_sync_out_settings_calb, :libximc), result_t, (device_t, Ptr{sync_out_settings_calb_t}, Ptr{calibration_t}), id, sync_out_settings_calb, calibration)
end

function get_sync_out_settings(id, sync_out_settings)
    ccall((:get_sync_out_settings, :libximc), result_t, (device_t, Ptr{sync_out_settings_t}), id, sync_out_settings)
end

function get_sync_out_settings_calb(id, sync_out_settings_calb, calibration)
    ccall((:get_sync_out_settings_calb, :libximc), result_t, (device_t, Ptr{sync_out_settings_calb_t}, Ptr{calibration_t}), id, sync_out_settings_calb, calibration)
end

function set_extio_settings(id, extio_settings)
    ccall((:set_extio_settings, :libximc), result_t, (device_t, Ptr{extio_settings_t}), id, extio_settings)
end

function get_extio_settings(id, extio_settings)
    ccall((:get_extio_settings, :libximc), result_t, (device_t, Ptr{extio_settings_t}), id, extio_settings)
end

function set_brake_settings(id, brake_settings)
    ccall((:set_brake_settings, :libximc), result_t, (device_t, Ptr{brake_settings_t}), id, brake_settings)
end

function get_brake_settings(id, brake_settings)
    ccall((:get_brake_settings, :libximc), result_t, (device_t, Ptr{brake_settings_t}), id, brake_settings)
end

function set_control_settings(id, control_settings)
    ccall((:set_control_settings, :libximc), result_t, (device_t, Ptr{control_settings_t}), id, control_settings)
end

function set_control_settings_calb(id, control_settings_calb, calibration)
    ccall((:set_control_settings_calb, :libximc), result_t, (device_t, Ptr{control_settings_calb_t}, Ptr{calibration_t}), id, control_settings_calb, calibration)
end

function get_control_settings(id, control_settings)
    ccall((:get_control_settings, :libximc), result_t, (device_t, Ptr{control_settings_t}), id, control_settings)
end

function get_control_settings_calb(id, control_settings_calb, calibration)
    ccall((:get_control_settings_calb, :libximc), result_t, (device_t, Ptr{control_settings_calb_t}, Ptr{calibration_t}), id, control_settings_calb, calibration)
end

function set_joystick_settings(id, joystick_settings)
    ccall((:set_joystick_settings, :libximc), result_t, (device_t, Ptr{joystick_settings_t}), id, joystick_settings)
end

function get_joystick_settings(id, joystick_settings)
    ccall((:get_joystick_settings, :libximc), result_t, (device_t, Ptr{joystick_settings_t}), id, joystick_settings)
end

function set_ctp_settings(id, ctp_settings)
    ccall((:set_ctp_settings, :libximc), result_t, (device_t, Ptr{ctp_settings_t}), id, ctp_settings)
end

function get_ctp_settings(id, ctp_settings)
    ccall((:get_ctp_settings, :libximc), result_t, (device_t, Ptr{ctp_settings_t}), id, ctp_settings)
end

function set_uart_settings(id, uart_settings)
    ccall((:set_uart_settings, :libximc), result_t, (device_t, Ptr{uart_settings_t}), id, uart_settings)
end

function get_uart_settings(id, uart_settings)
    ccall((:get_uart_settings, :libximc), result_t, (device_t, Ptr{uart_settings_t}), id, uart_settings)
end

function set_calibration_settings(id, calibration_settings)
    ccall((:set_calibration_settings, :libximc), result_t, (device_t, Ptr{calibration_settings_t}), id, calibration_settings)
end

function get_calibration_settings(id, calibration_settings)
    ccall((:get_calibration_settings, :libximc), result_t, (device_t, Ptr{calibration_settings_t}), id, calibration_settings)
end

function set_controller_name(id, controller_name)
    ccall((:set_controller_name, :libximc), result_t, (device_t, Ptr{controller_name_t}), id, controller_name)
end

function get_controller_name(id, controller_name)
    ccall((:get_controller_name, :libximc), result_t, (device_t, Ref{controller_name_t}), id, Ref(controller_name))
end

function set_nonvolatile_memory(id, nonvolatile_memory)
    ccall((:set_nonvolatile_memory, :libximc), result_t, (device_t, Ptr{nonvolatile_memory_t}), id, nonvolatile_memory)
end

function get_nonvolatile_memory(id, nonvolatile_memory)
    ccall((:get_nonvolatile_memory, :libximc), result_t, (device_t, Ptr{nonvolatile_memory_t}), id, nonvolatile_memory)
end

function set_emf_settings(id, emf_settings)
    ccall((:set_emf_settings, :libximc), result_t, (device_t, Ptr{emf_settings_t}), id, emf_settings)
end

function get_emf_settings(id, emf_settings)
    ccall((:get_emf_settings, :libximc), result_t, (device_t, Ptr{emf_settings_t}), id, emf_settings)
end

function set_engine_advansed_setup(id, engine_advansed_setup)
    ccall((:set_engine_advansed_setup, :libximc), result_t, (device_t, Ptr{engine_advansed_setup_t}), id, engine_advansed_setup)
end

function get_engine_advansed_setup(id, engine_advansed_setup)
    ccall((:get_engine_advansed_setup, :libximc), result_t, (device_t, Ptr{engine_advansed_setup_t}), id, engine_advansed_setup)
end

function set_extended_settings(id, extended_settings)
    ccall((:set_extended_settings, :libximc), result_t, (device_t, Ptr{extended_settings_t}), id, extended_settings)
end

function get_extended_settings(id, extended_settings)
    ccall((:get_extended_settings, :libximc), result_t, (device_t, Ptr{extended_settings_t}), id, extended_settings)
end

function command_stop(id)
    ccall((:command_stop, :libximc), result_t, (device_t,), id)
end

function command_power_off(id)
    ccall((:command_power_off, :libximc), result_t, (device_t,), id)
end

function command_move(id, Position, uPosition)
    ccall((:command_move, :libximc), result_t, (device_t, Cint, Cint), id, Position, uPosition)
end

function command_move_calb(id, Position, calibration)
    ccall((:command_move_calb, :libximc), result_t, (device_t, Cfloat, Ptr{calibration_t}), id, Position, calibration)
end

function command_movr(id, DeltaPosition, uDeltaPosition)
    ccall((:command_movr, :libximc), result_t, (device_t, Cint, Cint), id, DeltaPosition, uDeltaPosition)
end

function command_movr_calb(id, DeltaPosition, calibration)
    ccall((:command_movr_calb, :libximc), result_t, (device_t, Cfloat, Ptr{calibration_t}), id, DeltaPosition, calibration)
end

function command_home(id)
    ccall((:command_home, :libximc), result_t, (device_t,), id)
end

function command_left(id)
    ccall((:command_left, :libximc), result_t, (device_t,), id)
end

function command_right(id)
    ccall((:command_right, :libximc), result_t, (device_t,), id)
end

function command_loft(id)
    ccall((:command_loft, :libximc), result_t, (device_t,), id)
end

function command_sstp(id)
    ccall((:command_sstp, :libximc), result_t, (device_t,), id)
end

function get_position(id, the_get_position)
    ccall((:get_position, :libximc), result_t, (device_t, Ref{get_position_t}), id, the_get_position)
end

function get_position_calb(id, the_get_position_calb, calibration)
    ccall((:get_position_calb, :libximc), result_t, (device_t, Ptr{get_position_calb_t}, Ptr{calibration_t}), id, the_get_position_calb, calibration)
end

function set_position(id, the_set_position)
    ccall((:set_position, :libximc), result_t, (device_t, Ptr{set_position_t}), id, the_set_position)
end

function set_position_calb(id, the_set_position_calb, calibration)
    ccall((:set_position_calb, :libximc), result_t, (device_t, Ptr{set_position_calb_t}, Ptr{calibration_t}), id, the_set_position_calb, calibration)
end

function command_zero(id)
    ccall((:command_zero, :libximc), result_t, (device_t,), id)
end

function command_save_settings(id)
    ccall((:command_save_settings, :libximc), result_t, (device_t,), id)
end

function command_read_settings(id)
    ccall((:command_read_settings, :libximc), result_t, (device_t,), id)
end

function command_save_robust_settings(id)
    ccall((:command_save_robust_settings, :libximc), result_t, (device_t,), id)
end

function command_read_robust_settings(id)
    ccall((:command_read_robust_settings, :libximc), result_t, (device_t,), id)
end

function command_eesave_settings(id)
    ccall((:command_eesave_settings, :libximc), result_t, (device_t,), id)
end

function command_eeread_settings(id)
    ccall((:command_eeread_settings, :libximc), result_t, (device_t,), id)
end

function command_start_measurements(id)
    ccall((:command_start_measurements, :libximc), result_t, (device_t,), id)
end

function get_measurements(id, measurements)
    ccall((:get_measurements, :libximc), result_t, (device_t, Ptr{measurements_t}), id, measurements)
end

function get_chart_data(id, chart_data)
    ccall((:get_chart_data, :libximc), result_t, (device_t, Ptr{chart_data_t}), id, chart_data)
end

function get_serial_number(id, SerialNumber)
    ccall((:get_serial_number, :libximc), result_t, (device_t, Ptr{Cuint}), id, SerialNumber)
end

function get_firmware_version(id, Major, Minor, Release)
    ccall((:get_firmware_version, :libximc), result_t, (device_t, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), id, Major, Minor, Release)
end

function service_command_updf(id)
    ccall((:service_command_updf, :libximc), result_t, (device_t,), id)
end

function set_serial_number(id, serial_number)
    ccall((:set_serial_number, :libximc), result_t, (device_t, Ptr{serial_number_t}), id, serial_number)
end

function get_analog_data(id, analog_data)
    ccall((:get_analog_data, :libximc), result_t, (device_t, Ptr{analog_data_t}), id, analog_data)
end

function get_debug_read(id, debug_read)
    ccall((:get_debug_read, :libximc), result_t, (device_t, Ptr{debug_read_t}), id, debug_read)
end

function set_debug_write(id, debug_write)
    ccall((:set_debug_write, :libximc), result_t, (device_t, Ptr{debug_write_t}), id, debug_write)
end

function set_stage_name(id, stage_name)
    ccall((:set_stage_name, :libximc), result_t, (device_t, Ref{stage_name_t}), id, Ref(stage_name))
end

function get_stage_name(id, stage_name)
    ccall((:get_stage_name, :libximc), result_t, (device_t, Ref{stage_name_t}), id, stage_name)
end

function set_stage_information(id, stage_information)
    ccall((:set_stage_information, :libximc), result_t, (device_t, Ref{stage_information_t}), id, Ref(stage_information))
end

function get_stage_information(id, stage_information)
    ccall((:get_stage_information, :libximc), result_t, (device_t, Ref{stage_information_t}), id, Ref(stage_information))
end

function set_stage_settings(id, stage_settings)
    ccall((:set_stage_settings, :libximc), result_t, (device_t, Ptr{stage_settings_t}), id, stage_settings)
end

function get_stage_settings(id, stage_settings)
    ccall((:get_stage_settings, :libximc), result_t, (device_t, Ptr{stage_settings_t}), id, stage_settings)
end

function set_motor_information(id, motor_information)
    ccall((:set_motor_information, :libximc), result_t, (device_t, Ptr{motor_information_t}), id, motor_information)
end

function get_motor_information(id, motor_information)
    ccall((:get_motor_information, :libximc), result_t, (device_t, Ptr{motor_information_t}), id, motor_information)
end

function set_motor_settings(id, motor_settings)
    ccall((:set_motor_settings, :libximc), result_t, (device_t, Ptr{motor_settings_t}), id, motor_settings)
end

function get_motor_settings(id, motor_settings)
    ccall((:get_motor_settings, :libximc), result_t, (device_t, Ptr{motor_settings_t}), id, motor_settings)
end

function set_encoder_information(id, encoder_information)
    ccall((:set_encoder_information, :libximc), result_t, (device_t, Ptr{encoder_information_t}), id, encoder_information)
end

function get_encoder_information(id, encoder_information)
    ccall((:get_encoder_information, :libximc), result_t, (device_t, Ptr{encoder_information_t}), id, encoder_information)
end

function set_encoder_settings(id, encoder_settings)
    ccall((:set_encoder_settings, :libximc), result_t, (device_t, Ptr{encoder_settings_t}), id, encoder_settings)
end

function get_encoder_settings(id, encoder_settings)
    ccall((:get_encoder_settings, :libximc), result_t, (device_t, Ptr{encoder_settings_t}), id, encoder_settings)
end

function set_hallsensor_information(id, hallsensor_information)
    ccall((:set_hallsensor_information, :libximc), result_t, (device_t, Ptr{hallsensor_information_t}), id, hallsensor_information)
end

function get_hallsensor_information(id, hallsensor_information)
    ccall((:get_hallsensor_information, :libximc), result_t, (device_t, Ptr{hallsensor_information_t}), id, hallsensor_information)
end

function set_hallsensor_settings(id, hallsensor_settings)
    ccall((:set_hallsensor_settings, :libximc), result_t, (device_t, Ptr{hallsensor_settings_t}), id, hallsensor_settings)
end

function get_hallsensor_settings(id, hallsensor_settings)
    ccall((:get_hallsensor_settings, :libximc), result_t, (device_t, Ptr{hallsensor_settings_t}), id, hallsensor_settings)
end

function set_gear_information(id, gear_information)
    ccall((:set_gear_information, :libximc), result_t, (device_t, Ptr{gear_information_t}), id, gear_information)
end

function get_gear_information(id, gear_information)
    ccall((:get_gear_information, :libximc), result_t, (device_t, Ptr{gear_information_t}), id, gear_information)
end

function set_gear_settings(id, gear_settings)
    ccall((:set_gear_settings, :libximc), result_t, (device_t, Ptr{gear_settings_t}), id, gear_settings)
end

function get_gear_settings(id, gear_settings)
    ccall((:get_gear_settings, :libximc), result_t, (device_t, Ptr{gear_settings_t}), id, gear_settings)
end

function set_accessories_settings(id, accessories_settings)
    ccall((:set_accessories_settings, :libximc), result_t, (device_t, Ptr{accessories_settings_t}), id, accessories_settings)
end

function get_accessories_settings(id, accessories_settings)
    ccall((:get_accessories_settings, :libximc), result_t, (device_t, Ptr{accessories_settings_t}), id, accessories_settings)
end

function get_bootloader_version(id, Major, Minor, Release)
    ccall((:get_bootloader_version, :libximc), result_t, (device_t, Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), id, Major, Minor, Release)
end

function get_init_random(id, init_random)
    ccall((:get_init_random, :libximc), result_t, (device_t, Ptr{init_random_t}), id, init_random)
end

function get_globally_unique_identifier(id, globally_unique_identifier)
    ccall((:get_globally_unique_identifier, :libximc), result_t, (device_t, Ptr{globally_unique_identifier_t}), id, globally_unique_identifier)
end

function goto_firmware(id, ret)
    ccall((:goto_firmware, :libximc), result_t, (device_t, Ptr{UInt8}), id, ret)
end

function has_firmware(uri, ret)
    ccall((:has_firmware, :libximc), result_t, (Ptr{Cchar}, Ptr{UInt8}), uri, ret)
end

function command_update_firmware(uri, data, data_size)
    ccall((:command_update_firmware, :libximc), result_t, (Ptr{Cchar}, Ptr{UInt8}, UInt32), uri, data, data_size)
end

function write_key(uri, key)
    ccall((:write_key, :libximc), result_t, (Ptr{Cchar}, Ptr{UInt8}), uri, key)
end

function command_reset(id)
    ccall((:command_reset, :libximc), result_t, (device_t,), id)
end

function command_clear_fram(id)
    ccall((:command_clear_fram, :libximc), result_t, (device_t,), id)
end

function open_device(uri)
    ccall((:open_device, :libximc), device_t, (Cstring,), uri)
end

function close_device(id)
    ccall((:close_device, :libximc), result_t, (Ptr{device_t},), Ref(id))
end

function load_correction_table(id, namefile)
    ccall((:load_correction_table, :libximc), result_t, (Ptr{device_t}, Ptr{Cchar}), id, namefile)
end

function set_correction_table(id, namefile)
    ccall((:set_correction_table, :libximc), result_t, (device_t, Ptr{Cchar}), id, namefile)
end

function probe_device(uri)
    ccall((:probe_device, :libximc), result_t, (Ptr{Cchar},), uri)
end

function set_bindy_key(keyfilepath)
    ccall((:set_bindy_key, :libximc), result_t, (Ptr{Cchar},), keyfilepath)
end

function enumerate_devices(enumerate_flags, hints)
    ccall((:enumerate_devices, :libximc), Ptr{device_enumeration_t}, (Cint, Ptr{Cchar}), enumerate_flags, hints)
end

function free_enumerate_devices(device_enumeration)
    ccall((:free_enumerate_devices, :libximc), result_t, (device_enumeration_t,), device_enumeration)
end

function get_device_count(device_enumeration)
    ccall((:get_device_count, :libximc), Cint, (Ptr{device_enumeration_t},), device_enumeration)
end

function get_device_name(device_enumeration, device_index)
    ccall((:get_device_name, :libximc), pchar, (Ptr{device_enumeration_t}, Cint), device_enumeration, device_index)
end

function get_enumerate_device_serial(device_enumeration, device_index, serial)
    ccall((:get_enumerate_device_serial, :libximc), result_t, (device_enumeration_t, Cint, Ptr{UInt32}), device_enumeration, device_index, serial)
end

function get_enumerate_device_information(device_enumeration, device_index, device_information)
    ccall((:get_enumerate_device_information, :libximc), result_t, (device_enumeration_t, Cint, Ptr{device_information_t}), device_enumeration, device_index, device_information)
end

function get_enumerate_device_controller_name(device_enumeration, device_index, controller_name)
    ccall((:get_enumerate_device_controller_name, :libximc), result_t, (Ptr{device_enumeration_t}, Cint, Ref{controller_name_t}), device_enumeration, device_index, Ref(controller_name))
end

function get_enumerate_device_stage_name(device_enumeration, device_index, stage_name)
    ccall((:get_enumerate_device_stage_name, :libximc), result_t, (Ptr{device_enumeration_t}, Cint, Ref{stage_name_t}), device_enumeration, device_index, stage_name)
end

function get_enumerate_device_network_information(device_enumeration, device_index, device_network_information)
    ccall((:get_enumerate_device_network_information, :libximc), result_t, (device_enumeration_t, Cint, Ptr{device_network_information_t}), device_enumeration, device_index, device_network_information)
end

# no prototype is found for this function at ximc.h:5342:20, please use with caution
function reset_locks()
    ccall((:reset_locks, :libximc), result_t, ())
end

function ximc_fix_usbser_sys(device_uri)
    ccall((:ximc_fix_usbser_sys, :libximc), result_t, (Ptr{Cchar},), device_uri)
end

function msec_sleep(msec)
    ccall((:msec_sleep, :libximc), Cvoid, (Cuint,), msec)
end

function ximc_version(version)
    ccall((:ximc_version,:libximc), Cvoid, (Ptr{Cchar},), version)
end

function logging_callback_stderr_wide(loglevel, message, user_data)
    ccall((:logging_callback_stderr_wide, :libximc), Cvoid, (Cint, Ptr{Cwchar_t}, Ptr{Cvoid}), loglevel, message, user_data)
end

function logging_callback_stderr_narrow(loglevel, message, user_data)
    ccall((:logging_callback_stderr_narrow, :libximc), Cvoid, (Cint, Ptr{Cwchar_t}, Ptr{Cvoid}), loglevel, message, user_data)
end

function set_logging_callback(logging_callback, user_data)
    ccall((:set_logging_callback, :libximc), Cvoid, (logging_callback_t, Ptr{Cvoid}), logging_callback, user_data)
end

function get_status(id, status)
    ccall((:get_status, :libximc), result_t, (device_t, Ref{status_t}), id, status)
end

function get_status_calb(id, status, calibration)
    ccall((:get_status_calb, :libximc), result_t, (device_t, Ptr{status_calb_t}, Ptr{calibration_t}), id, status, calibration)
end

function get_device_information(id, device_information)
    ccall((:get_device_information, :libximc), result_t, (device_t, Ref{device_information_t}), id, Ref(device_information))
end

function command_wait_for_stop(id, refresh_interval_ms)
    ccall((:command_wait_for_stop, :libximc), result_t, (device_t, UInt32), id, refresh_interval_ms)
end

function command_homezero(id)
    ccall((:command_homezero, :libximc), result_t, (device_t,), id)
end