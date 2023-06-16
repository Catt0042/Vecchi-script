
catt = {}



------------------------------------------  DATA BASE  ------------------------------------------
catt.db = {}



function catt.db.get_groups()	
	catt.db.groups = {}	
	for coal_name, coal_value in pairs (env.mission.coalition) do
		if coal_name == 'blue' or coal_name == 'red' then --- coal_name == 'white'????
			local coalition = coal_name
			for country_name, country_value in pairs(coal_value.country) do
				for object_name, object_value in pairs (country_value) do
					if	object_name == 'plane' or object_name == 'helicopter' or object_name == "ship" or object_name == "vehicle" or object_name == "static" then
						local category = object_name
						for group_number, group_data in pairs (object_value.group) do 
							if group_data.groupId then
								local group_name = env.getValueDictByKey(group_data.name)
								local group_desc = Group.getByName(group_name):getUnits()[1]:getDesc()
								local _data = {
									group_name = group_name,
									coalition = coalition,
									category = category,
									id = group_data.groupId,
									task = group_data.task,
									rcs =  Unit.getDescByName(group_data.units[1].type).RCS,
									group_units = {},
									status = 'not engaged',
								}
                                for unit_name, unit_value in pairs (Group.getByName(group_name):getUnits()) do
                                	local data_of_unit = {
                                    		unit_name = unit_value:getName(),
                                    		attributes = unit_value:getDesc().attributes,
                                        	displayName = unit_value:getDesc().displayName
                                    	}
                                    	_data.group_units[#_data.group_units + 1] = data_of_unit
								end	
								if group_desc.fuelMassMax then
									_data.max_fuel = group_desc.fuelMassMax
								end
								catt.db.groups[#catt.db.groups + 1] = _data
							end
						end
					end
				end
			end
		end
	end
end



function catt.db.get_db_group(group_name)
	for i, value in pairs (catt.db.groups) do
		if value.group_name and value.group_name == group_name then
			return value
		end
	end
end


function catt.db.get_bullseye(coalition)
    local bullseye
	if coalition == 'red' then
		bullseye = catt.utils.vec3(env.mission.coalition.red.bullseye)
	end
    if coalition == 'blue' then
		bullseye = catt.utils.vec3(env.mission.coalition.blue.bullseye)
	end
return bullseye
end





catt.db.obj_specs = {
	['E-2C 1984'] = {
		model = 'E-2C 1984',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 250, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['E-2C 1990'] = {
		model = 'E-2C 1990',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 300.2, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
	
	['E-2C 1995'] = {
		model = 'E-2C 1995',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 349.9, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['E-2D 2016'] = {
		model = 'E-2D 2016',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 349.9, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 40, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
	
		
	['E-3A 1980'] = {
		model = 'E-3A 1980',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 300.2, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['E-3B 1985'] = {
		model = 'E-3B 1985',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 349.9, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['E-3C 2004'] = {
		model = 'E-3C 2004',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 349.9, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 40, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['E-3G 2015'] = {
		model = 'E-3G 2015',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 349.9, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 40, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['F-4E 1977'] = {
		model = 'F-4E 1977',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 60, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-10, 10}, --degrees
		radar_scan_period = 35,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['F-5E 1975'] = {
		model = 'F-5E 1975',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 16, --nm
		radar_azimuth = {-45, 45}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-10, 10}, --degrees
		radar_scan_period = 30,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
		
	['F-14A 1977'] = {
		model = 'F-14A 1977',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 180, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-14B 1990'] = {
		model = 'F-14B 1990',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 180, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-15A 1977'] = {
		model = 'F-15A 1977',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 95, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-15C 1984'] = {
		model = 'F-15C 1984',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 95, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-15C 1987'] = {
		model = 'F-15C 1987',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 100, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-15C 2003'] = {
		model = 'F-15C 2003',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 120, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 65, --kts
        antenna_height = 0, --feet
		},
	
	['F-15E 1990'] = {
		model = 'F-15E 1990',
		type = 'bomber',
		has_air_radar = 'yes',
		radar_range = 100, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['F-16A 1981'] = {
		model = 'F-16A 1981',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F-16C 1985'] = {
		model = 'F-16C 1985',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 60, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['F/A-18A 1984'] = {
		model = 'F/A-18A 1984',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 80, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['F/A-18C 1988'] = {
		model = 'F/A-18C 1988',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 80, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['M2000C 1986'] = {
		model = 'M2000C 1986',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 65, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['M2000-5 1999'] = {
		model = 'M2000-5 1999',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 80, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
		
	['AJS-37 1994'] = {
		model = 'AJS-37 1994',
		type = 'bomber',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['AV-8B PLUS 1993'] = {
		model = 'AV-8B PLUS 1993',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 60, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	
		
	['Tornado ECR 1986'] = {
		model = 'Tornado ECR 1986',
		type = 'ew support',
		has_air_radar = 'no',
		has_comms_jammer = 'no',
		has_radar_jammer = 'yes',
		radar_jammer_number = 2,
		radar_jammer_power = 8,
		},	
		
	['Tornado ECR 1998'] = {
		model = 'Tornado ECR 1998',
		type = 'ew support',
		has_air_radar = 'no',
		has_comms_jammer = 'no',
		has_radar_jammer = 'yes',		
		radar_jammer_number = 2,
		radar_jammer_power = 10,
		},	
	
	['EA-6B 1986'] = {
		model = 'EA-6B 1986',
		type = 'ew support',
		has_air_radar = 'no',
		has_comms_jammer = 'no',
		has_radar_jammer = 'yes',
		radar_jammer_number = 6,
		radar_jammer_power = 12,
		},	
	
	['EC-130H COMPASS CALL 1983'] = {
		model = 'EC-130H COMPASS CALL 1983',
		type = 'ew support',
		has_air_radar = 'no',
		has_comms_jammer = 'yes',
		comms_jammer_number = 6,
		comms_jammer_range = 500,
		has_radar_jammer = 'yes',
		radar_jammer_number = 2,
		radar_jammer_power = 8,
		},	
		
	-----------------------------------RED-----------------------------------
	
	['A-50 1986'] = {
		model = 'A-50 1986',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 215, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-30, -30}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	['MIG-21S 1968'] = {
		model = 'MIG-21S 1968',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 16, --nm
		radar_azimuth = {-30, 30}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-10, 5}, --degrees
		radar_scan_period = 35,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['MIG-21BIS 1973'] = {
		model = 'MIG-21BIS 1973',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 16, --nm
		radar_azimuth = {-30, 30}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-5, 10}, --degrees
		radar_scan_period = 35,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['MIG-23M 1974'] = {
		model = 'MIG-23M 1974',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 30, --nm
		radar_azimuth = {-30, 30}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-5, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['MIG-23ML 1981'] = {
		model = 'MIG-23ML 1981',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-30, 30}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-10, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['MIG-25PD 1980'] = {
		model = 'MIG-25PD 1980',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 90, --nm
		radar_azimuth = {-56, 56}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-15, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
	
	['MIG-29A 1984'] = {
		model = 'MIG-29A 1984',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['MIG-29S 1987'] = {
		model = 'MIG-29S 1987',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 50, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-40, 40}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['MIG-31 1982'] = {
		model = 'MIG-31 1982',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 170, --nm
		radar_azimuth = {-70, 70}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-70, 70}, --degrees
		radar_scan_period = 80,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
	['SU-24M 1983'] = {
		model = 'SU-24M 1983',
		type = 'bomber',
		has_air_radar = 'yes',
		radar_range = 80, --nm
		radar_azimuth = {-40, 40}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 10}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},	
		
	['SU-27S 1986'] = {
		model = 'SU-27S 1986',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 90, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['SU-30 2013'] = {
		model = 'SU-30 2013',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 160, --nm
		radar_azimuth = {-70, 70}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-50, 50}, --degrees
		radar_scan_period = 55,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['SU-33 1995'] = {
		model = 'SU-33 1995',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 90, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	['SU-34 2012'] = {
		model = 'SU-34 2012',
		type = 'bomber',
		has_air_radar = 'yes',
		radar_range = 160, --nm
		radar_azimuth = {-70, 70}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-50, 50}, --degrees
		radar_scan_period = 55,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
	
	
	['J-11A 1994'] = {
		model = 'J-11A 1994',
		type = 'fighter',
		has_air_radar = 'yes',
		radar_range = 90, --nm
		radar_azimuth = {-60, 60}, --degrees   PRESI DA DB-SENSORS.LUA
		radar_elevation = {-30, 30}, --degrees
		radar_scan_period = 40,
		radar_radial_velocity_min = 70, --kts
        antenna_height = 0, --feet
		},
		
		['KJ-2000 2003'] = {
		model = 'KJ-2000 2003',
		type = 'awacs',
		has_air_radar = 'yes',
		radar_range = 350, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, -10}, --degrees
		radar_scan_period = 10,
		radar_radial_velocity_min = 60, --kts
        antenna_height = 8, --feet
		priority_for_jammer = 58, --min 51 per ewr e awacs
		},
		
	
	
	['1L13 EWR'] = {
		model = '1L13 EWR',
		type = 'ewr',
		has_air_radar = 'yes',
		radar_range = 269.98, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 60}, --degrees
		radar_scan_period = 20,
		radar_radial_velocity_min = 100, --kts
		radar_beamwidth = 8,
		radar_first_sideobe_ratio = 0.3, -- 30° di sidelobe in base alla distanza
		radar_power = 8007,
        antenna_height = 39, --feet
		priority_for_jammer = 52, --min 51 per ewr e awacs
		},
	
	['SA-10 1981'] = {
		model = 'SA-10 1981',
		type = 'lr sam',
		has_air_radar = 'yes',
		radar_range = 190, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 60}, --degrees
		radar_scan_period = 7,
		radar_radial_velocity_min = 30, --kts
		radar_beamwidth = 6,
		radar_first_sideobe_ratio = 0.25, -- 30° di sidelobe in base alla distanza
		radar_power = 38313,
        antenna_height = 43, --feet
		missile_max_range = 40,
		missile_max_alt = 100000,
		priority_for_jammer = 100,
		},
	
	['SA-3 1965'] = {
		model = 'SA-3 1965',
		type = 'mr sam',
		has_air_radar = 'yes',
		radar_range = 134.98, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 45}, --degrees
		radar_scan_period = 9,
		radar_radial_velocity_min = 100, --kts
		radar_beamwidth = 8,
		radar_first_sideobe_ratio = 0.35, -- 30° di sidelobe in base alla distanza
		radar_power = 1321,
        antenna_height = 30, --feet
		missile_max_range = 11.2,
		missile_max_alt = 20500,
		priority_for_jammer = 82,
		},
		
	['SA-6 1967'] = { 
		model = 'SA-6 1967',
		type = 'mr sam',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 60}, --degrees
		radar_scan_period = 6,
		radar_radial_velocity_min = 35, --kts
		radar_beamwidth = 2,
		radar_first_sideobe_ratio = 0.5, -- 30° di sidelobe in base alla distanza
		radar_power = 1759,
        antenna_height = 15, --feet
		missile_max_range = 19.2,
		missile_max_alt = 26000,
		priority_for_jammer = 86,
		},
		
	['Hawk 1978'] = { 
		model = 'Hawk 1978',
		type = 'mr sam',
		has_air_radar = 'yes',
		radar_range = 54, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 60}, --degrees
		radar_scan_period = 5,
		radar_radial_velocity_min = 30, --kts
		radar_beamwidth = 2,
		radar_first_sideobe_ratio = 0.45, -- 30° di sidelobe in base alla distanza
		radar_power = 2260,
        antenna_height = 12, --feet
		missile_max_range = 25.6,
		missile_max_alt = 45000,
		priority_for_jammer = 88,
		},
		
	['SA-11 1982'] = { 
		model = 'SA-11 1982',
		type = 'mr sam',
		has_air_radar = 'yes',
		radar_range = 40, --nm
		radar_azimuth = {-180, 180}, --degrees
		radar_elevation = {-15, 60}, --degrees
		radar_scan_period = 5,
		radar_radial_velocity_min = 25, --kts
		radar_beamwidth = 2,
		radar_first_sideobe_ratio = 0.4, -- 30° di sidelobe in base alla distanza
		radar_power = 2002,
        antenna_height = 14, --feet
		missile_max_range = 20.2,
		missile_max_alt = 48000,
		priority_for_jammer = 93,
		},
		
	}

	


------------------------------------------  UTILS  ------------------------------------------

catt.utils ={}


function catt.utils.round(number, decimals)
  local factor = 10^(decimals or 0)
  return math.floor(number * factor + 0.5) / factor
end 


function catt.utils.round_angle(angle)
	if angle < 0 then 
    	angle = angle + 360
    elseif angle > 360 then
        angle = angle - 360
    end
return angle 
end


function catt.utils.vec3(vector)
    if vector.z then
		return vector
	else 
		return {
			x = vector.x, 
			z = vector.y,
			y = land.getHeight({vector.x, vector.y})
		}
	end
end



function catt.utils.get_dhms()
	local abs_time = timer.getAbsTime( )
	local dhms = {d = 0, h = 0, m = 0, s = 0}
		if abs_time > 86400 then
			while abs_time > 86400 do
				dhms.d = dhms.d + 1
				abs_time = abs_time - 86400
			end
		end
		if abs_time > 3600 then
			while abs_time > 3600 do
				dhms.h = dhms.h + 1
				abs_time = abs_time - 3600
			end
		end
		if abs_time > 60 then
			while abs_time > 60 do
				dhms.m = dhms.m + 1
				abs_time = abs_time - 60
			end
		end
		dhms.s = abs_time
		return dhms
end


function catt.utils.deep_copy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
			local new_table = {}
			lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
			return setmetatable(new_table, getmetatable(object))
	end
return _copy(object)
end
  
  
function catt.utils.check_point_in_zone(point, zone_points, altitude)
	local point_x = point.x
	local point_z = point.z
	local counter = 0
	local new_zone = catt.utils.deep_copy(zone_points)
	local min_altitude
	local max_altitude
    if altitude then
		min_altitude = catt.conv.feet_to_m(altitude[1])
		max_altitude = catt.conv.feet_to_m(altitude[2])
	end
	if not altitude or ((point.y > min_altitude) and (point.y < max_altitude)) then
		local polysize = #new_zone
		new_zone[#new_zone + 1] = new_zone[1]
		for i = 1, polysize do
			if ((new_zone[i].z <= point_z) and (new_zone[i+1].z > point_z)) or ((new_zone[i].z > point_z) and (new_zone[i+1].z <= point_z)) then
				local vt = (point_z - new_zone[i].z) / (new_zone[i+1].z - new_zone[i].z)
				if (point_x < new_zone[i].x + vt*(new_zone[i+1].x - new_zone[i].x)) then
					counter = counter + 1
				end
			end
		end
		return counter%2 == 1
	else
		return false
	end
end
	

	
	
	
function catt.utils.is_active(group_name)
	if Group.getByName(group_name) and Group.getByName(group_name):isExist() == true then
		local unit_obj = Group.getByName(group_name):getUnits()[1]
		if unit_obj and unit_obj:isActive() == true then
			return 'yes'
		else
			return 'no'
		end
	else
		return 'no'
    end
end	






--riordina una tavola sulla base di un parametro param che è contenuto nella tabella (1° livello)
--esempio: catt.utils.sort_table (target_data, 'group_name', 'priority', 'lower', 3)   --- 'higher' o 'lower'
-----sorta la tavola target_data, in base al valore di target_data.priority (partendo dal valore più piccolo)
-----ha bisogno del riferimento target_data.group_name per ritrovare gli elementi della tavola
-----mette solo i primi tre valori
function catt.utils.sort_table(tab, reference, param, order, element_number)
	local function sort_by_value(tbl)
		local keys = {}
		for key in pairs(tbl) do
			table.insert(keys, key)
		end
			local function compare(a, b)
				if order == 'lower' then
                	return tbl[a]  < tbl[b]
                else 
                	return tbl[a]  > tbl[b]
                end
			end
		table.sort(keys, compare)
		return keys
	end
    
	local sorted_index = {}
		for id, value in pairs (tab) do 
			sorted_index[value[reference]] = value[param]
		end
		local sortedKeys = sort_by_value(sorted_index)

    	local final_sort = {}
		if element_number then
			for i=1, element_number do
				for el_id, el_value in pairs (tab) do
					if el_value[reference] == sortedKeys[i] then
                		table.insert (final_sort, el_value)
               		end
                end
			end	
		else	
			for name_id, name_value in ipairs (sortedKeys) do
				for el_id, el_value in pairs (tab) do
					if el_value[reference] == name_value then
						table.insert (final_sort, el_value)
					end
				end
			end
		end
--trigger.action.outText(mist.utils.tableShow(final_sort), 5)
return final_sort
end





function catt.utils.is_group_player(group_name)
	local unit_name = Group.getByName(group_name):getUnits()[1]:getName()
	local player_name = world.getPlayer():getName()
	if unit_name == player_name then
		return 'yes'
	else
		return 'no'
	end
end


function catt.utils.degrees_to_dms(degrees)
	local d = math.floor(degrees)
    local m_raw = (degrees - d) * 60
    local m = math.floor(m_raw)
    local s = math.floor((m_raw - m) * 60)
    local dms = {d=d, m=m, s=s}
return dms
end



function catt.utils.vec_to_latlong(point)
    local latitude, longitude, altitude = coord.LOtoLL(point)
    local lat_hemi
    local long_hemi
    if latitude >= 0 then
        lat_hemi = 'n'
    else
        lat_hemi = 's'
    end
    if longitude >= 0 then
        long_hemi = 'e' 
    else
        long_hemi = 'w'
    end
	latitude = math.abs(latitude)
	longitude = math.abs(longitude)
    local latlong_point ={}
    	latlong_point.lat = catt.utils.degrees_to_dms(latitude)
    	latlong_point.lat.hemi = lat_hemi
    	latlong_point.long = catt.utils.degrees_to_dms(longitude)
    	latlong_point.long.hemi = long_hemi
    	latlong_point.alt = catt.conv.m_to_feet(altitude)
return latlong_point
end


function catt.utils.latlong_to_vec (point)
	local latitude = point.lat.d + (point.lat.m / 60) + (point.lat.s / 3600)
    local longitude = point.long.d + (point.long.m / 60) + (point.long.s / 3600) 
    local altitude = point.alt * 0.3048
    if point.lat.hemi == 's' then
      latitude = latitude * (-1)
	end
  	if point.long.hemi == 'w' then
    	longitude = longitude * (-1)
	end    
    local vec_point =  coord.LLtoLO(latitude, longitude, altitude)  
return vec_point
end






function catt.utils.elaborate_string(string, var)
	local function upper_first(first, rest)
  		return first:upper()..rest:lower()
    end
    local function first_word_upper(str)
    	return (str:gsub("^%l", string.upper))
	end
 	if var then
        if var == 'all_capital' then
    		local res = string.gsub (string, '_', ' ')
				res = res:gsub( "(%a)([%w_']*)", upper_first )
    		return res
		elseif var == 'first_capital' then
            local res = string.gsub (string, '_', ' ')
				res = res:gsub( res, first_word_upper )
    		return res
        elseif var == 'all_lower' then
        	local res = string.gsub (string, '_', ' ')
            return res
        end
 	end
end    




------------------------------------------  CONVERSIONS  ------------------------------------------

catt.conv = {}
function catt.conv.nm_to_km(value)
	return value*1.852
end

function catt.conv.km_to_nm(value)
	return value/1.852
end

function catt.conv.feet_to_m(value)
	return value*0.3048
end

function catt.conv.m_to_feet(value)
	return value/0.3048
end

function catt.conv.kts_to_kmh(value)
	return value*1.852
end

function catt.conv.kmh_to_kts(value)
	return value/1.852
end	

function catt.conv.kts_to_ms(value)
	return value*0.514444
end

function catt.conv.ms_to_kts(value)
	return value/0.514444
end



function catt.conv.dhms_to_abs(dhms)
	local d = dhms.d * 8640
	local h = dhms.h * 3600
	local m = dhms.m * 60
	local s = dhms.s 
	local abs_time = d + h + m + s
	return abs_time
end


function catt.conv.ias_to_gs(ias, altitude)
    local gs = ias / (1- (6.87535 * 10^(-6) * altitude))^2.128
    return gs
end

------------------------------------------  MEASURES  ------------------------------------------




catt.meas = {}	

function catt.meas.dist2d (point1, point2) -- in miglia nautiche
	local point1 = catt.utils.vec3(point1)
	local point2 = catt.utils.vec3(point2)
	local distance = ((point1.x - point2.x)^2 + (point1.z - point2.z)^2)^0.5
    local distance = distance / 1852
    return distance
end


	
function catt.meas.dist3d (point1, point2) -- in miglia nautiche
	local point1 = catt.utils.vec3(point1)
	local point2 = catt.utils.vec3(point2)
	local dist2d = catt.meas.dist2d (point1, point2)
	local dist3d = ((point1.y - point2.y)^2 + (dist2d*1852)^2)^0.5
	local dist3d = dist3d / 1852
    return dist3d
end





-- indica il target aspect a partire dal naso di unit1_pos (target) rispetto a get_bearing in gradi 
function catt.meas.get_aspect(unit1_pos, unit2_pos)
    local bearing = math.rad(catt.meas.get_bearing(unit1_pos, unit2_pos))
    local heading = math.rad(catt.meas.get_heading(unit1_pos))
    local aspect =  bearing - heading
      if aspect > 2 * math.pi then
       aspect = aspect - (2 * math.pi)
      end
      if aspect < 0 then
        aspect = aspect + (2 * math.pi)
      end
      return math.deg(aspect)
end


--
function catt.meas.aspect_usaf(unit1_pos, unit2_pos)
    local aspect_angle = catt.meas.get_aspect(unit1_pos, unit2_pos)
		if aspect_angle <= 30 or aspect_angle >= 330 then
			bogey_aspect = "hot"
		end
		if aspect_angle > 30 and aspect_angle < 150 then
			bogey_aspect = "flanking"
		end
		if aspect_angle > 210 and aspect_angle < 330 then
			bogey_aspect = "flanking"
		end
		if aspect_angle >= 150 and aspect_angle <= 210 then
			bogey_aspect = "cold"
		end
    return bogey_aspect
end


function catt.meas.get_target_track(unit_pos)
    local heading = catt.meas.get_heading(unit_pos)
	local track
    if heading >= 0 and heading < 22.5 then
		track = "tracking_n"
    end
    if heading >= 22.5 and heading < 67.5 then
		track = "tracking_ne"
    end
    if heading >= 67.5 and heading < 112.5 then
		track = "tracking_e"
    end
    if heading >= 112.5 and heading < 157.5 then
		track = "tracking_se"
    end
	if heading >= 157.5 and heading < 202.5 then
		track = "tracking_s"
    end
	if heading >= 202.5 and heading < 247.5 then
		track = "tracking_sw"
    end
	if heading >= 247.5 and heading < 292.5 then
		track = "tracking_w"
    end
	if heading >= 292.5 and heading < 337.5 then
		track = "tracking_nw"
    end
	if heading >= 337.5 and heading <= 360 then
		track = "tracking_n"
    end
return track
end



-- misura il bearing da unit1_pos a unit2_pos in gradi in 2d
function catt.meas.get_bearing(unit1_pos, unit2_pos)
	local bearing_vector = catt.vector.sub(unit2_pos.p, unit1_pos.p)
	local bearing = catt.meas.get_direction(bearing_vector)
return bearing
end


-- misura il bearing da unit1_point a unit2_point in gradi in 2d
function catt.meas.get_bearing_with_points(unit1_point, unit2_point)
	local bearing_vector = catt.vector.sub(unit2_point, unit1_point)
	local bearing = catt.meas.get_direction(bearing_vector)
return bearing
end

	
-- misura la direzione del vettore in gradi  in 2d
function catt.meas.get_direction(vector)
    local direction = math.atan2(vector.z, vector.x)
		if direction < 0 then
			direction = direction + (2 * math.pi) 
		end
    return math.deg(direction)
end



-- misura heading in gradi in 2d
function catt.meas.get_heading(unit_pos)
      local heading = (math.atan2(unit_pos.x.z, unit_pos.x.x))
      if heading < 0 then
		heading = heading + 2*math.pi
      end
      return math.deg(heading)
end



-- misura l'elevazione del vettore in gradi  in 2d
function catt.meas.get_elevation(vector)
	local norm_vector = catt.vector.normalize(vector)
    local elevation = math.asin(norm_vector.y)
    return math.deg(elevation)
end



function catt.meas.get_altitude(unit)
    local altitude = unit:getPoint().y * 3.28084
    return altitude
end    


function catt.meas.get_altitude_point(point)
    local altitude = point.y * 3.28084
    return altitude
end    


function catt.meas.get_true_speed(unit) --kts
    local unitvel = unit:getVelocity()
    local unitspeed = ((unitvel.x^2 + unitvel.y^2 + unitvel.z^2)^0.5) * 1.94384
    return unitspeed
end

function catt.meas.get_ground_speed(unit) --kts
    local unitvel = unit:getVelocity()
    local unitspeed = ((unitvel.x^2 + unitvel.z^2)^0.5) * 1.94384
    return unitspeed
end


function catt.meas.get_real_altitude(point, force_altitude, force_qnh)
	local force_qnh = force_qnh * 3.386389
	local obj_pos_sealevel = {x=point.x, z=point.z, y=0}
	local t_sea, p_sea = atmosphere.getTemperatureAndPressure(obj_pos_sealevel) 
		p_sea = p_sea /1000 -- 133.322
	local altitude_diff = catt.conv.m_to_feet((1 - ((force_qnh/p_sea)^(1/5.25527789)))*(t_sea/0.0065))
	local real_altitude = force_altitude + altitude_diff
--trigger.action.outText('real_altitude: '..real_altitude, 5)
return real_altitude
end



function catt.meas.get_turn_dir(heading_degrees, turn_degrees)
	local heading_opp
    local turn_dir
    if heading_degrees < 180 then
        heading_opp = heading_degrees + 180
        if turn_degrees > heading_degrees and turn_degrees < heading_opp then
            turn_dir = 'right'
       	else 
            turn_dir = 'left'
        end
  	else
     	heading_opp = heading_degrees - 180
      	if turn_degrees < heading_degrees and turn_degrees > heading_opp then
            turn_dir = 'left'
       	else 
            turn_dir = 'right'
        end
    end
return turn_dir
end


------------------------------------------  VECTORS  ------------------------------------------





catt.vector = {}

function catt.vector.add(vector1, vector2)
	return {x = vector1.x + vector2.x, y = vector1.y + vector2.y, z = vector1.z + vector2.z}
end

function catt.vector.sub(vector1, vector2)
	return {x = vector1.x - vector2.x, y = vector1.y - vector2.y, z = vector1.z - vector2.z}
end

function catt.vector.magnitude(vector)
	return (vector.x^2 + vector.y^2 + vector.z^2)^0.5
end

function catt.vector.normalize(vector)
	local magnitude = catt.vector.magnitude(vector)
	return { x = vector.x/magnitude, y = vector.y/magnitude, z = vector.z/magnitude }
end


function catt.vector.dot (vector1, vector2)
	return vector1.x*vector2.x + vector1.y*vector2.y + vector1.z*vector2.z
end

function catt.vector.cross(vector1, vector2)
	return { x = vector1.y*vector2.z - vector1.z*vector2.y, y = vector1.z*vector2.x - vector1.x*vector2.z, z = vector1.x*vector2.y - vector1.y*vector2.x}
end

function catt.vector.angle_to_vector(angle)
    local angle = math.rad(angle)
    local vector = {
    	z = math.sin(angle),
    	x = math.cos(angle),
    	y = 0,
    }
return vector
end


function catt.vector.rotate_vector(vector, angle)
    local angle = math.rad(angle)
    local vector = {
    	x = vector.x * math.cos(angle) - vector.z  *math.sin(angle),
    	z = vector.x * math.sin(angle) + vector.z * math.cos(angle),
    	y = 0,
    }
return vector
end


function catt.vector.vector_scaling(vector, k)
    local vector = {
    	x = vector.x * k,
    	z = vector.z * k,
    	y = vector.y * k,
    }
return vector
end

 



------------------------------------------  RADIO  ------------------------------------------


catt.radio = {}

function catt.radio.subs_compiler(subtitles_data, broadcaster_name, broadcaster_voice)
	local subtitles = "["..string.upper(broadcaster_name)..']'
	for number, value in ipairs(subtitles_data) do
        for voice_name, voice_data in pairs (sound_files) do
			if voice_name == broadcaster_voice then
			
				for sound_name, sound_data in pairs (voice_data) do
				
				
					if value == sound_name then
						if sound_data.subtitle then
							value = sound_data.subtitle
						end
					end
				end	
			end	
		end
			if value == ',' or value == '.' or value == ':' then
				subtitles = subtitles..value
			else
				subtitles = subtitles..' '..value
			end
	end
return subtitles
end



function catt.radio.get_message_duration(message_data)
	local duration = 0
		for number, value in ipairs(message_data) do 
			if value.length then
				duration = duration + value.length
			end
		end
return duration
end



	
function catt.radio.gett_voice(group_name)
	for package_number, package_value in pairs (ato) do
		for group_number, group_value in pairs (package_value.groups) do
			if group_value.group_name == group_name then
				return group_value.voice
			end
		end
	end
end




	

	
function catt.radio.talker(message)
    local broadcaster_name = message.options.broadcaster_name
	local broadcaster_voice = message.options.broadcaster_voice
	local broadcaster = Group.getByName(broadcaster_name):getUnits()[1]:getController()
	local message_data = {}
		for word_name, word_data in ipairs (message) do
			for voice_name, voice_data in pairs (sound_files) do
				if voice_name == broadcaster_voice then
					for sound_name, sound_data in pairs (voice_data) do
	
					if word_data == sound_name then
						message_data[#message_data + 1] = sound_data
					end
					end
				end
			end
    	end
	local subtitles = message.options.subtitles
	local duration = catt.radio.get_message_duration(message_data)
		local function transmit(msg)	
			broadcaster:setCommand(msg)
		end
	local first_message = {
		id = 'TransmitMessage', 
		params = {
			duration = duration * 4,
			subtitle = subtitles,
			file = "catt_sounds/static.ogg",
			} 
		}
	transmit(first_message)	
	local _timer = timer.getTime() + 0.8
	for part_name, part_value in ipairs (message_data) do
		local length = part_value.length
        local radio_message = {
			id = 'TransmitMessage', 
			params = {
				file = part_value.file,
				} 
			}
		timer.scheduleFunction(transmit, radio_message, _timer)
        _timer = _timer + length - 0.02  -------------------
	end
end




	
	

