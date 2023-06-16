

catt.c2 = {}


------------------------------------------  DB TOOLS  ------------------------------------------

function catt.c2.insert_specs_and_mission_profile_in_groups_db() ---anche le basi aeree
	local function get_specs(model_name)
		for i, value in pairs (catt.db.obj_specs) do
			if value.model and value.model == model_name then
				return value
			end
		end
	end
	for package_name, package_value in pairs (ato) do
		if package_value.groups then
			for group_name, group_value in pairs (package_value.groups) do
				if group_value.group_name and group_value.model then
					local ato_mission = group_value
					for group_name_2, group_value_2 in pairs (catt.db.groups) do
						if group_value_2.group_name and group_value_2.group_name == group_value.group_name then                        
							local specs = get_specs(group_value.model)	
							group_value_2.specs = specs
							group_value_2.ato_mission = ato_mission
						end
					end
				end
			end
		end
	end
	for atc_id, atc_value in pairs (ato.atc_airbases) do
		for base_id, base_value in pairs (aco.airbases) do
			if atc_value.name == base_id then
				base_value.atc = atc_value
			end
		end
	end
end




function catt.c2.get_airborne_groups()
	local function check_in_air(group)
		if group and group:isExist() == true then
			for index, data in pairs(group:getUnits()) do
				if Unit.getByName(data:getName()):isActive() then
					if Unit.getByName(data:getName()): inAir() == true then
						return true
					end
				end
			end
		else
			return false
		end
	end
	for group_name, group_value in pairs (catt.db.groups) do            
			if check_in_air(Group.getByName(group_value.group_name)) == true then --IMPORTANTE, controlla se esiste	
				group_value.airborne = "yes"
			else 
				group_value.airborne = "no"
			end
	end
return timer.getTime() + 5
end









	
------------------------------------------  ACO  ------------------------------------------

catt.aco = {}


function catt.aco.get_acm(acm_name)
	for i, value in pairs (aco) do
		if value.acm_name and value.acm_name == acm_name then
			return value
		end
	end
end



function catt.aco.create_oriented_box(fez_name)
	local fez_data = catt.aco.get_acm(fez_name)
    local cap_point = catt.aco.get_nav_fix_by_name(fez_data.cap_point)
    local bearing_vector = catt.vector.angle_to_vector(fez_data.bearing)
    local ahead_vector = catt.vector.vector_scaling(bearing_vector, (fez_data.length * 1852 * (2/3)))
    local right_vector = catt.vector.vector_scaling(catt.vector.rotate_vector(bearing_vector, 90), (fez_data.width * 1852 * (1/2)))
    local left_vector = catt.vector.vector_scaling(right_vector, -1)
    local behind_vector = catt.vector.vector_scaling(ahead_vector, (-1/2))
    local points = {
        [1] =catt.vector.add(catt.vector.add(cap_point, ahead_vector), right_vector),
        [2] =catt.vector.add(catt.vector.add(cap_point, ahead_vector), left_vector),
        [3] =catt.vector.add(catt.vector.add(cap_point, behind_vector), right_vector), 
        [4] =catt.vector.add(catt.vector.add(cap_point, behind_vector), left_vector),
        }
    fez_data.points = points
--trigger.action.outText(mist.utils.tableShow(points), 20)
--trigger.action.markToAll( x_val + 1 , 'points', points[1])
--x_val = x_val + 5   
end


function catt.aco.insert_ip_in_aco()
	for coal_name, coal_value in pairs (env.mission.coalition) do
		if coal_name == 'blue' or coal_name == 'red' then --- coal_name == 'white'????
			for nav_name, nav_value in pairs (coal_value.nav_points) do
                local vec = {x=nav_value.x, z=nav_value.y, y=land.getHeight({x=nav_value.x, y=nav_value.y})}
                local latlong = catt.utils.vec_to_latlong(vec)
				local name = nav_value.callsignStr
                local point = {
					x = vec.x,
					y = vec.y,
					z = vec.z,
                    lat = latlong.lat,
                    long = latlong.long,
                    alt = latlong.alt,
				}		
				aco.nav_fixes[name] = point
			end
		end
	end	
end			


function catt.aco.build_ab_radio_system()
	local radio_band_in_use = options.radio_band_in_use
    for ab_id, ab_value in pairs (aco.airbases) do
		if ab_value.radio_freq then
			for band_id, band_value in pairs (ab_value.radio_freq) do
				if band_id == radio_band_in_use then
					ab_value.appr_freq = band_value.appr_freq
					ab_value.tower_freq = band_value.tower_freq
					if band_value.final_controller_freq then
						ab_value.final_controller_freq = band_value.final_controller_freq
					end
				end
			end
		end
		for group_id, group_value in pairs (catt.db.groups) do
			if ab_value.appr_cs then
				if ab_value.appr_cs == group_value.group_name then
					local freq = { 
						id = 'SetFrequency', 
						params = { 
							frequency = (ab_value.appr_freq * 1000000), 
							modulation = 0, 
						} 
					}
					Group.getByName(group_value.group_name):getUnits()[1]:getController():setCommand(freq)
				end
			end
			if ab_value.final_controller_cs then
				if ab_value.final_controller_cs == group_value.group_name then
					local freq = { 
						id = 'SetFrequency', 
						params = { 
							frequency = (ab_value.appr_freq * 1000000), 
							modulation = 0, 
						} 
					}
					Group.getByName(group_value.group_name):getUnits()[1]:getController():setCommand(freq)
				end
			end
		end
	end
end
					
					

function catt.aco.build_vectors_approach()
    for ab_id, ab_value in pairs (aco.airbases) do
        if ab_value.vectors_approach then
            for rwy_id, rwy_value in pairs (ab_value.vectors_approach) do
				local treshold_ll_point = {lat= rwy_value.threshold.lat, long= rwy_value.threshold.long, alt= rwy_value.threshold.alt}
--                local treshold_vec_point = catt.utils.latlong_to_vec(treshold_ll_point)
--                	rwy_value.threshold.x = treshold_vec_point.x
--					rwy_value.threshold.z = treshold_vec_point.z
--					rwy_value.threshold.y = treshold_vec_point.y
                local rwy_end_ll_point = {lat= rwy_value.rwy_end.lat, long= rwy_value.rwy_end.long, alt= rwy_value.rwy_end.alt}
                local rwy_end_vec_point = catt.utils.latlong_to_vec(rwy_end_ll_point)
                	rwy_value.rwy_end.x = rwy_end_vec_point.x
					rwy_value.rwy_end.z = rwy_end_vec_point.z
					rwy_value.rwy_end.y = rwy_end_vec_point.y
                local iaf_ll_point = {lat= rwy_value.iaf.lat, long= rwy_value.iaf.long, alt= rwy_value.iaf.alt}
                local iaf_vec_point = catt.utils.latlong_to_vec(iaf_ll_point)
                	rwy_value.iaf.x = iaf_vec_point.x
					rwy_value.iaf.z = iaf_vec_point.z
					rwy_value.iaf.y = iaf_vec_point.y
				if iaf_2 then
					local iaf_2_ll_point = {lat= rwy_value.iaf_2.lat, long= rwy_value.iaf_2.long, alt= rwy_value.iaf_2.alt}
					local iaf_2_vec_point = catt.utils.latlong_to_vec(iaf_2_ll_point)
						rwy_value.iaf_2.x = iaf_2_vec_point.x
						rwy_value.iaf_2.z = iaf_2_vec_point.z
						rwy_value.iaf_2.y = iaf_2_vec_point.y
				end
                
                local rwy_true_heading = catt.meas.get_bearing_with_points(rwy_value.threshold, rwy_value.rwy_end)
                local rwy_mag_heading = rwy_true_heading - options.mag_var 
                	rwy_value.rwy_heading = rwy_mag_heading                
            end
      	end
 	end
end


function catt.aco.get_nav_fix_by_name(fix_name)
	for fix_id, fix_value in pairs (aco.nav_fixes) do
		if fix_id == fix_name then
			return fix_value
		end
	end
end

function catt.aco.get_airbase_by_name(airbase_name)
	for id, value in pairs (catt.aco.airbases) do
		if id == airbase_name then
			return value
		end
	end
end



function catt.aco.create_aco()
	for id, value in pairs (aco.nav_fixes) do
        local ll_point = {lat= value.lat, long= value.long, alt= value.alt}
        local vec_point = catt.utils.latlong_to_vec(ll_point)
		value.x = vec_point.x
		value.z = vec_point.z
		value.y = vec_point.y
    end
	for id, value in pairs (aco.airbases) do
        local ll_point = {lat= value.lat, long= value.long, alt= value.alt}
        local vec_point = catt.utils.latlong_to_vec(ll_point)
		value.x = vec_point.x
		value.z = vec_point.z
		value.y = vec_point.y
    end
    
    catt.aco.insert_ip_in_aco()
	catt.aco.build_vectors_approach()
	catt.aco.build_ab_radio_system()
	
	for i, value in pairs (aco.acm) do
		if value.type and value.type == 'oriented_box' then
			catt.aco.create_oriented_box(value.acm_name)
		--elseif
		
		end
	end
end



------------------------------------------  aaaargghh  ------------------------------------------







function catt.c2.evaluate_air_threat(target_data, plane_data)
	local plane_pos = Group.getByName(plane_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
    local distance = catt.meas.dist3d (plane_pos.p, target_pos.p)
	local bullseye = catt.db.get_bullseye(plane_data.coalition)
	local bullseye_reference = catt.c2.get_bullseye_reference(target_pos, bullseye)
	local altitude = target_pos.p.y * 3.28084
    local threat_factor = 100 / distance
    --local target_aspect = catt.meas.get_aspect(target_pos, plane_pos)
    local target_aspect = catt.meas.aspect_usaf(target_pos, plane_pos)
	if target_aspect == 'hot' then
		threat_factor = threat_factor * 1.2
	end 
	if target_aspect == 'cold' then
		threat_factor = threat_factor * 0.8
	end 
	local target_info = {
		group_name = target_data.group_name,
		position = target_pos,
		number_of_units = #Group.getByName(target_data.group_name):getUnits(),
        threat_factor = threat_factor,
        bullseye_reference = bullseye_reference,
        altitude = altitude,
		track = catt.meas.get_target_track(target_pos)
	}
return target_info
end





function catt.c2.sort_target_list(target_list)
			local function select_highest(target_list)
				local max_value = 0
				local result = {}
				for i, value in pairs (target_list) do
					if value.threat_factor > max_value then
						max_value = value.threat_factor
						result = value			
					end
				end
			--result.old_threat_factor = result.threat_factor
			result.threat_factor = 0
			return result
			end
	local sorted_target_list = {}
	local number_of_contacts = #target_list
	if number_of_contacts > 3 then-------------standard di comunicazione picture, massimo 3 gruppi
		number_of_contacts = 3
	end
	for i = 1, number_of_contacts, 1 do
		sorted_target_list[#sorted_target_list + 1] = select_highest(target_list)
	end
return sorted_target_list
end


function catt.c2.get_bullseye_reference(target_pos, bullseye)
	local bullseye_pos = {p = bullseye}
	local distance = catt.meas.dist3d (target_pos.p, bullseye_pos.p)
    local bearing = catt.meas.get_bearing(bullseye_pos, target_pos)
	local result = {bearing, distance}
return result
end





function catt.c2.degrees_for_message(degrees, approx_five_degrees)
    local rounded_degrees = catt.utils.round(degrees)
    local heading_length = string.len (tostring(rounded_degrees))
    local last_digit = tonumber(string.sub (rounded_degrees, -1, -1))
    if approx_five_degrees == 'yes' then
		if last_digit < 7.5 and last_digit > 2.5 then
			last_digit = 5
		elseif last_digit > 7.5 then
			last_digit = 0
			rounded_degrees = rounded_degrees + 10
		elseif last_digit < 2.5 then
            last_digit = 0
        end
    end
	
	local result = {}
    if heading_length == 3 then
        result[1] = tostring(string.sub(rounded_degrees, 1, 1))
        result[2] = tostring(string.sub(rounded_degrees, 2, 2))
        result[3] = tostring(last_digit)
	end
    if heading_length == 2 then
        result[1] = '0'
        result[2] = tostring(string.sub(rounded_degrees, 1, 1))
        result[3] = tostring(last_digit)    
    end
    if heading_length == 1 then
        result[1] = '0'
        result[2] = '0'
        result[3] = tostring(last_digit)   
    end
	if heading_length == 1 and last_digit == 0 then
        result[1] = '3'
        result[2] = '6'
        result[3] = '0'
 	end
--trigger.action.outText(mist.utils.tableShow(result), 20)
return result
end


function catt.c2.digits_for_message(digits)
    local integers = math.floor(digits)
    local number_of_integers = string.len (tostring(integers)) 
    local decimals = catt.utils.round(digits - integers, 3)
    local number_of_decimals = string.len (tostring(decimals)) - 2
    	decimals = decimals * 10^number_of_decimals
    local digits_length = string.len (tostring(digits))	
    
	local result = {}
    
	for i=1, number_of_integers do
        result[#result + 1] = tostring(string.sub(integers, i, i))
	end
    
	if number_of_decimals > 0 then 
    	result[#result + 1] = 'point'
 	end
    
	for i=1, number_of_decimals do
        result[#result + 1] = tostring(string.sub(decimals, i, i))
	end

	return result
end



function catt.c2.distance_for_message(distance)
	local rounded_distance = catt.utils.round(distance)
	local last_digit = tonumber(string.sub (rounded_distance, -1, -1))
	local result = {}

	if rounded_distance <= 20 then
		result[1] = tostring(rounded_distance)
	elseif rounded_distance > 20 and rounded_distance <= 100 then 
		if last_digit == 0 then
            result[1] = tostring(rounded_distance)
        else
            result[1] = tostring(string.sub(rounded_distance, 1, 1))..'0'
            result[2] = tostring(last_digit)
      	end
	elseif rounded_distance > 100 then 
        if last_digit == 0 then
            if string.sub(rounded_distance, 2, 2) == '0' then
                result[1] = tostring(string.sub(rounded_distance, 1, 1))..'00'
            else
                result[1] = tostring(string.sub(rounded_distance, 1, 1))..'00'
                result[2] = tostring(string.sub(rounded_distance, 2, 2))..'0'
          	end
		end
        if last_digit ~= 0 then
            if (string.sub(rounded_distance, 2, 2)) == '0' then
                result[1] = tostring(string.sub(rounded_distance, 1, 1))..'00'
                result[2] = tostring(last_digit)
            else
                result[1] = tostring(string.sub(rounded_distance, 1, 1))..'00'
                result[2] = tostring(string.sub(rounded_distance, 2, 2))..'0'
                result[3] = tostring(last_digit)
          	end
      	end
  	end
--trigger.action.outText(mist.utils.tableShow(result), 20)
return result
end




function catt.c2.altitude_for_message(altitude, approx_to_one_thousand)
    local thousands
    local hundreds
    local result = {}
    
    if approx_to_one_thousand == 'yes' then
        thousands = catt.utils.round(altitude / 1000)
        hundreds = 0
		if thousands == 0 then
			thousands = 1
		end
   	else
        thousands = math.floor(altitude / 1000)
        hundreds = catt.utils.round(((altitude / 1000) - thousands)* 10) 
        if thousands == 0 and hundreds == 0 then
			hundreds = 1
		end
	end      
	
    local last_digit = tonumber(string.sub (thousands, -1, -1))

	if thousands == 0 then
        result[#result + 1] = tostring(hundreds)
		result[#result + 1] = 'hundred'
    elseif thousands > 0 and thousands <= 20 then
		result[#result + 1] = tostring(thousands)
		result[#result + 1] = 'thousand'
        if hundreds > 0 then
          	result[#result + 1] = tostring(hundreds)
        	result[#result + 1] = 'hundred'
        end
	elseif thousands > 20 then 
		if last_digit == 0 then
            result[#result + 1] = tostring(thousands)
            result[#result + 1] = 'thousand'
        else
            result[#result + 1] = tostring(string.sub(thousands, 1, 1))..'0'
            result[#result + 1] = tostring(last_digit)
            result[#result + 1] = 'thousand'
      	end
        if hundreds > 0 then
          	result[#result + 1] = tostring(hundreds)
        	result[#result + 1] = 'hundred'
        end
	end
--trigger.action.outText(mist.utils.tableShow(result), 20)	
return result
end	




			
-- comunica la picture, se è clean, non comunica niente
function catt.c2.pass_picture(radar_name, plane_name)
	local radar_data = catt.db.get_db_group(radar_name)
	local plane_data = catt.db.get_db_group(plane_name)
    local radar_picture = radar_data.picture
	local broadcaster_name = radar_name
	local target_list = {}
    local distance_measure
    local altitude_measure
    if options.measures == 'imperial' then
		distance_measure = 'nm'
		altitude_measure = 'feet'
	else
		distance_measure = 'km'
		altitude_measure = 'meters'
	end
    for i, target_name in pairs (radar_picture) do
        local target_data = catt.db.get_db_group(target_name)
        	if target_data.coalition ~= plane_data.coalition then
				local target_info = catt.c2.evaluate_air_threat(target_data, plane_data)
					target_list[#target_list + 1] = target_info
            end
  	end
	local sorted_target_list = catt.c2.sort_target_list(target_list)
	local message = {
		[1] = radar_name, 
        [2] = 'pause_025'
		}
	local subtitles = {
		[1] = radar_name, 
		[2] = ',',  
		}
	
	if #sorted_target_list == 0 then
		--message[#message + 1] = 'picture_clean'
		--subtitles[#subtitles + 1] = 'picture_clean'	
		return nil
    else
		
		if #sorted_target_list > 1 then
			message[#message + 1] = tostring(#sorted_target_list)
			subtitles[#subtitles + 1] = tostring(#sorted_target_list)
			message[#message + 1] = 'groups'	
			subtitles[#subtitles + 1] = 'groups'	
		else	 
			message[#message + 1] = 'single'
			subtitles[#subtitles + 1] = 'single'
			message[#message + 1] = 'group'	
			subtitles[#subtitles + 1] = 'group'	
		end	
		subtitles[#subtitles + 1] = ','
		for name, value in ipairs (sorted_target_list) do
	
			if value.group_name then
				message[#message + 1] = 'pause_05'
				message[#message + 1] = 'group'
				subtitles[#subtitles + 1] = 'group'
				
				message[#message + 1] = 'bullseye'
				subtitles[#subtitles + 1] = 'bullseye'
				message[#message + 1] = catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[1]
				message[#message + 1] = catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[2]
				message[#message + 1] = catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[3]
				subtitles[#subtitles + 1] = catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[1]..catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[2]..catt.c2.degrees_for_message(value.bullseye_reference[1], 'yes')[3]
				message[#message + 1] = 'for'
				subtitles[#subtitles + 1] = 'for'
				local distance_for_message = catt.c2.distance_for_message(value.bullseye_reference[2])
					for dist_name, dist_value in ipairs (distance_for_message) do
						message[#message + 1] = dist_value
					end
                
trigger.action.outText(mist.utils.tableShow(distance_for_message), 20)	

				subtitles[#subtitles + 1] =  catt.utils.round(value.bullseye_reference[2]) --catt.c2.distance_for_message(value.bullseye_reference[2])[1]--..catt.c2.distance_for_message(value.bullseye_reference[2])[2]..catt.c2.distance_for_message(value.bullseye_reference[2])[3]
				message[#message + 1] = distance_measure
				subtitles[#subtitles + 1] = distance_measure
				subtitles[#subtitles + 1] = ','	
				message[#message + 1] = 'at'	
				subtitles[#subtitles + 1] = 'at'	
				local altitude_for_message = catt.c2.altitude_for_message(value.altitude, 'yes')
					for alt_name, alt_value in ipairs (altitude_for_message) do
						message[#message + 1] = alt_value
					end
				subtitles[#subtitles + 1] =  catt.utils.round(value.altitude / 1000)..',000'
				message[#message + 1] = altitude_measure
				subtitles[#subtitles + 1] = altitude_measure
				subtitles[#subtitles + 1] = ','	
				message[#message + 1] = value.track
				subtitles[#subtitles + 1] = value.track
			end
		end
	end	
		message.options = {}
		message.options.broadcaster_name = broadcaster_name
    local broadcaster_voice = catt.radio.gett_voice(broadcaster_name)
		message.options.broadcaster_voice = broadcaster_voice
		message.options.subtitles = catt.radio.subs_compiler(subtitles, radar_name, broadcaster_voice)
 
--trigger.action.outText(message.options.subtitles, 1)
----------------- MANCA PID!!!!!!!!!!!!!!!---------------------------

    catt.radio.talker(message)

end 



------------------------------------------  EW  ------------------------------------------

catt.ew = {}


-- jammer_type = 'comms' o 'radar' o 'both'
-- is_active = 'yes' o 'no', 
function catt.ew.set_jammer(jammer_name, jammer_type, is_active) 
	local jammer_data = catt.db.get_db_group(jammer_name)
	if jammer_type == 'comms' then
		jammer_data.is_jamming_comms = is_active
	end
	if jammer_type == 'radar' then
		jammer_data.is_jamming_radar = is_active
	end 
	if jammer_type == 'both' then
		jammer_data.is_jamming_comms = is_active
		jammer_data.is_jamming_radar = is_active
	end
end





--- lo script accende tutti i jammer e i relativi sweep e fa partire il controller
function catt.ew.init()
	for obj_id, obj_value in pairs (catt.db.groups) do
		if obj_value.specs and obj_value.specs.has_comms_jammer and obj_value.specs.has_comms_jammer == 'yes' then
			obj_value.is_jamming_comms = 'yes'
            obj_value.comms_jammed_list = {}
			timer.scheduleFunction(catt.ew.comms_jammer_sweep, obj_value, timer.getTime() + 2)
		end
		if obj_value.specs and obj_value.specs.has_radar_jammer and obj_value.specs.has_radar_jammer == 'yes' then
			obj_value.is_jamming_radar = 'yes'
			timer.scheduleFunction(catt.ew.radar_jammer_sweep, obj_value, timer.getTime() + 2)
		end
	end
timer.scheduleFunction(catt.ew.comms_jammer_controller, nil, timer.getTime() + 1)
end



function catt.ew.comms_jammer_controller()
	catt.ew.comms_jammed_list = {}
	for obj_id, obj_value in pairs (catt.db.groups) do
		if obj_value.is_jamming_comms and obj_value.is_jamming_comms == 'yes' then
			for target_id, target_value in pairs (obj_value.comms_jammed_list) do
				table.insert(catt.ew.comms_jammed_list, target_value)
			end
		end  
	end
return timer.getTime() + 15		
end









function catt.ew.check_comms_jamming_range(jammer_data, target_data)
	local jammer_pos = Group.getByName(jammer_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
	local range = catt.meas.dist3d (jammer_pos.p, target_pos.p)
	local max_range = jammer_data.specs.comms_jammer_range
    if range < max_range then
		return 'yes'
	else
		return 'no'
	end
end



	

function catt.ew.comms_targeting(jammer_data, target_list)
	local jamming_bullseye_point = catt.aco.get_nav_fix_by_name(jammer_data.ato_mission.jamming_bullseye_point)
    local comms_jammer_number = jammer_data.specs.comms_jammer_number
	local sorted_table = {}
    for target_id, target_value in pairs (target_list) do
        local priority = 1
        local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
        local range = catt.meas.dist3d (jamming_bullseye_point, target_pos.p)	
        	if range > 200 then
            	priority = 0.2
            elseif range > 50 and range < 100 then
            	priority = 0.5   
            end

        	if target_value.specs and target_value.specs.type == 'ewr' then
    	        priority = priority * 100
        	elseif target_value.specs and target_value.specs.type == 'awacs' then
    	        priority = priority * 100
			elseif target_value.specs and target_value.specs.type == 'lr sam' then
    	        priority = priority * 48
			elseif target_value.specs and target_value.specs.type == 'mr sam' then
    	        priority = priority * 45
			elseif target_value.specs and target_value.specs.type == 'sr sam' then
    	        priority = priority * 30
        	elseif target_value.specs and target_value.specs.type == 'fighter' then
    	        priority = priority * 25
			else
    	        priority = priority * 5
        	end

        	target_value.comms_targeting = priority
  	end
		sorted_table = catt.utils.sort_table (target_list, 'group_name', 'comms_targeting', 'higher', comms_jammer_number)  
    
    --trigger.action.outText(mist.utils.tableShow(sorted_table[1]), 20)
	
    for obj_id, obj_value in pairs (sorted_table) do --rimuove il comms_targeting poiché non serve più
      		obj_value.comms_targeting = nil 
    end
        
	return sorted_table
end
	
	


function catt.ew.comms_jammer_sweep(jammer_data)
	local jammer_name = jammer_data.group_name
	jammer_data.comms_jammed_list = {}  -- importante, azzera i bersagli ingaggiati prima di controllare se jamma
	local target_list = {}
	if jammer_data.is_jamming_comms == 'yes' then	
		if catt.utils.is_active(jammer_name) == 'yes' then
			for target_id, target_data in pairs (catt.db.groups) do
				if target_data.coalition ~= jammer_data.coalition then 
					if not target_data.not_jammable or target_data.not_jammable == 'no' then 
						if catt.utils.is_active(target_data.group_name) == 'yes' then
							if catt.ew.check_comms_jamming_range(jammer_data, target_data) == 'yes' then
								table.insert(target_list, target_data)
							end
						end
					end
				end
			end
		end
	end
	
	if #target_list > 0 then
        jammer_data.comms_jammed_list =	catt.ew.comms_targeting(jammer_data, target_list) 
	end	
return timer.getTime() + 20	  
end




----------------------------------------------------------
------------RADAR--------------
----------------------------------------------------------




function catt.ew.has_search_radar_active(group_data)
    local group_units = Group.getByName(group_data.group_name):getUnits()
    local counter = 0
    for unit_name, unit_value in pairs (group_units) do
		local unit_name = unit_value:getName()
        local unit_attributes = unit_value:getDesc().attributes
		local has_search_radar = 'no'
        if unit_attributes['SAM SR'] and unit_attributes['SAM SR'] == true then
           	has_search_radar = 'yes'
		elseif unit_attributes['AWACS'] and unit_attributes['AWACS'] == true then
           	has_search_radar = 'yes'
		elseif unit_attributes['EWR'] and unit_attributes['EWR'] == true then
           	has_search_radar = 'yes'
		end
		if has_search_radar == 'yes' and unit_value:isActive() == true then
			local radar, target =  Unit.getByName(unit_name):getRadar()
			if radar == true then
--trigger.action.outText(group_data.group_name..' radar active' ,2)
				counter = counter + 1
			end
		end
	end 
	if counter >= 1 then
        return 'yes'
     else
        return 'no'
	end
end






function catt.ew.radar_targeting(jammer_data, target_list)
    		local function assign_jammers(target_list)
				local max_value = 0
				local group_name 
				for i, value in ipairs (target_list) do 
					if value.jamming_params.priority > max_value then
						max_value = value.jamming_params.priority 
						group_name = value.group_name
					end
				end
				for i, value in ipairs (target_list) do 
					if value.group_name == group_name then
						value.jamming_params.jammers_employed = value.jamming_params.jammers_employed + 1
						value.jamming_params.priority = value.jamming_params.priority/2				
					end
				end
			end
    
    local radar_jammer_number = jammer_data.specs.radar_jammer_number
    for target_id, target_value in pairs (target_list) do 
    	if target_value.specs then
            	target_value.jamming_params = {}        
            local jammer_altitude = catt.meas.get_altitude(Group.getByName(jammer_data.group_name):getUnits()[1])
            local jammer_pos = Group.getByName(jammer_data.group_name):getUnits()[1]:getPosition()
    		local priority = target_value.specs.priority_for_jammer
			local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
			local distance = catt.meas.dist3d (jammer_pos.p, target_pos.p)

			if target_value.specs.type == 'ewr' or target_value.specs.type == 'awacs' then
				if distance > (target_value.specs.radar_range * 1.2) then
					priority = priority * 0.2
				end
			elseif target_value.specs.type == 'lr sam' or target_value.specs.type == 'mr sam' or target_value.specs.type == 'sr sam' then
                if jammer_altitude < (target_value.specs.missile_max_alt * 1.2) then
					if distance > (target_value.specs.radar_range * 1.2) then
						priority = priority * 0.2
					end
				else 
					priority = 5
				end
			end
            local jamming_params = {
					target_pos = target_pos,
					distance = distance,
					priority = priority,
                	jammers_employed = 0,
					jammer_specs = jammer_data.specs,
					jammer_name = jammer_data.group_name,
					jammer_pos = jammer_pos,
					jammer_altitude = jammer_altitude,
				}
            
			target_value.jamming_params = jamming_params
		end
	end
            
    for i=1, radar_jammer_number do
    	assign_jammers(target_list)
	end

return target_list
end




	
function catt.ew.get_jammed_sector(target_value)
    local jammer_pos = target_value.jamming_params.jammer_pos
	local target_pos = target_value.jamming_params.target_pos
	local distance = 10 --target_value.jamming_params.distance
	local radar_range = target_value.specs.radar_range
	local radar_beamwidth = target_value.specs.radar_beamwidth
	local radar_first_sideobe_ratio = target_value.specs.radar_first_sideobe_ratio
	local first_sl_dist = radar_range * radar_first_sideobe_ratio
    local second_sl_dist = first_sl_dist / 2
    local third_sl_dist = second_sl_dist / 2
    local jammed_sector = {}  
	if distance < third_sl_dist then
        jammed_sector.azimuth = {-60, 60}
        jammed_sector.elevation = {-5, 5}
    elseif distance < second_sl_dist then
        jammed_sector.azimuth = {-30, 30}
        jammed_sector.elevation = {-4, 4}
    elseif distance < first_sl_dist then
        jammed_sector.azimuth = {-15, 15}
        jammed_sector.elevation = {-3, 3}
    elseif distance > first_sl_dist then
        jammed_sector.azimuth = { -(radar_beamwidth/2), (radar_beamwidth/2)}
        jammed_sector.elevation = {-2, 2}
    end
--trigger.action.outText('radar_range: '..radar_range, 1) 
--trigger.action.outText(mist.utils.tableShow(jammed_sector), 1) 
    return jammed_sector
end







function catt.ew.radar_jammer_sweep(jammer_data)
    local jammer_name = jammer_data.group_name
	local target_list = {}
	if jammer_data.is_jamming_radar == 'yes' then	
		if catt.utils.is_active(jammer_name) == 'yes' then
			for target_id, target_data in pairs (catt.db.groups) do
				if target_data.coalition ~= jammer_data.coalition then
					if not target_data.not_jammable or target_data.not_jammable == 'no' then --prevede unità invisibili al jammer
						if catt.utils.is_active(target_data.group_name) == 'yes' then
							if catt.ew.has_search_radar_active(target_data) == 'yes' then
                                table.insert(target_list, target_data)
							end
						end
					end
				end
			end
		end
	end
	if #target_list > 0 then
		local sorted_target_list = catt.ew.radar_targeting(jammer_data, target_list)
        catt.ew.employ_jammer(sorted_target_list)
	end
	
return timer.getTime() + 20	  
end



function catt.ew.employ_jammer(target_list)
	for target_id, target_value in pairs (target_list) do
		if target_value.jamming_params.jammers_employed and target_value.jamming_params.jammers_employed > 0 then
            target_value.is_radar_jammed = 'yes'
			target_value.jamming_params.radar_jammed_sector = catt.ew.get_jammed_sector(target_value) 
		else
            target_value.is_radar_jammed = 'no'
        end
	end
end



------------------------------------------  DETECTION  ------------------------------------------


catt.detect = {}



function catt.detect.get_azimuth(radar_pos, target_pos) -- da un valore da -180 a +180
	local bear_vector =  catt.vector.sub(target_pos.p, radar_pos.p)
	local bearing = math.rad(catt.meas.get_direction (bear_vector))
	local heading = math.rad(catt.meas.get_direction (radar_pos.x))    
	local azimuth =  bearing - heading 
	if azimuth > math.pi then
	azimuth = azimuth - (2 * math.pi) 
	end
	if azimuth <= -math.pi then
		azimuth = azimuth + (2 * math.pi)
	end
return math.deg(azimuth)
end



function catt.detect.get_elevation(radar_pos, target_pos) 
	local bear_vector =  catt.vector.sub(target_pos.p, radar_pos.p)
	local elevation = catt.meas.get_elevation(bear_vector)
return elevation
end



function catt.detect.get_intersect_angle(radar_pos, target_pos)
    local alpha = math.rad(catt.detect.get_azimuth(target_pos, radar_pos ))
    if alpha < 0 and alpha > -math.pi/2 then
        alpha = - alpha
        factor = -1
    elseif alpha <= -math.pi/2 then
		alpha = alpha + math.pi
        factor = 1
    elseif alpha > 0 and alpha < math.pi/2 then
        alpha = alpha
        factor = -1
    elseif alpha >= math.pi/2 then
		alpha = math.pi - alpha
        factor = 1
    end
alpha = math.deg(alpha)
    return alpha, factor
end    



function catt.detect.is_inside_scan_sector(radar_data, target_data)   
	local radar_pos = Group.getByName(radar_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
	local azimuth = catt.detect.get_azimuth(radar_pos, target_pos)
	local elevation = catt.detect.get_elevation(radar_pos, target_pos)
	local radar_azimuth = radar_data.specs.radar_azimuth
	local radar_elevation = radar_data.specs.radar_elevation 
--trigger.action.outText((target_data.group_name..' - azimuth: '..azimuth), 5)
--trigger.action.outText((target_data.group_name..' - elevation: '..elevation), 5)
--trigger.action.outText(mist.utils.tableShow(radar_azimuth), 10) 
		if azimuth > radar_azimuth[1] and azimuth < radar_azimuth[2] then
        	if elevation > radar_elevation[1] and elevation < radar_elevation[2] then
            	return 'yes'
            else 
				return 'no'
			end
		end
end



function catt.detect.is_in_los(radar_data, target_data)
	local radar_pos = Group.getByName(radar_data.group_name):getUnits()[1]:getPosition().p
	local radar_height = catt.conv.m_to_feet(radar_pos.y) + radar_data.specs.antenna_height
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition().p
    local target_height = catt.conv.m_to_feet(target_pos.y)
	local radar_horizon = 1.23 * ((radar_height)^(1/2) + (target_height)^(1/2))
    local range = catt.meas.dist3d (radar_pos, target_pos)
    if range < radar_horizon then
        return 'yes'
    else
        return 'no'
	end
end



function catt.detect.is_in_range(radar_data, target_data)
    local radar_pos = Group.getByName(radar_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
    local range = catt.meas.dist3d (radar_pos.p, target_pos.p)
    local radar_range = ((target_data.rcs/10)^(1/4)) * radar_data.specs.radar_range
    	if range < radar_range then
        	return 'yes'
        else
			return 'no'
		end
end



function catt.detect.has_ground_clutter(radar_data, target_data)
	local radar_pos = Group.getByName(radar_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
    local elevation = catt.detect.get_elevation(radar_pos, target_pos) 
    --local aspect = catt.meas.get_aspect(target_pos, radar_pos)
	local detection_prob = 1
		local radar_v_vector = Group.getByName(radar_data.group_name):getUnits()[1]:getVelocity()
		local radar_vel = ((radar_v_vector.x^2 + radar_v_vector.y^2 + radar_v_vector.z^2)^0.5) * 1.94384
		local radar_azimuth = catt.detect.get_azimuth(radar_pos, target_pos)
		local radar_rad_vel = math.cos(math.rad(math.abs(radar_azimuth))) * radar_vel
		local target_v_vector = Group.getByName(target_data.group_name):getUnits()[1]:getVelocity()
		local target_vel = ((target_v_vector.x^2 + target_v_vector.y^2 + target_v_vector.z^2)^0.5) * 1.94384
		local target_alpha, target_factor =  catt.detect.get_intersect_angle (radar_pos, target_pos)
		local target_rad_vel = math.cos(math.rad(target_alpha)) * target_factor * target_vel
        local target_rel_vel = radar_rad_vel - target_rad_vel
		if  math.abs(target_rad_vel) > radar_data.specs.radar_radial_velocity_min then
			if math.abs(target_rel_vel) > radar_data.specs.radar_radial_velocity_min then
				detection_prob = detection_prob * 1
			else
				detection_prob = detection_prob * 0.4
			end
		else
			detection_prob = detection_prob * 0.3
		end
	if elevation > 0 then 		
		detection_prob = detection_prob * 1.8
	else    
		detection_prob = detection_prob * 1
	end
--trigger.action.outText(target_data.group_name..'\naspect: '..aspect..'\ndetection_prob: '..detection_prob, 10)
    local dice_roll = math.random()
    if detection_prob > dice_roll then
        return 'no'
    else
        return 'yes'
    end
end




function catt.detect.is_radar_jammed(radar_data, target_data)
	if radar_data.is_radar_jammed == 'yes' then
        local jammer_data = catt.db.get_db_group(radar_data.jamming_params.jammer_name)
		if jammer_data.is_jamming_radar == 'yes' then
			local radar_pos = Group.getByName(radar_data.group_name):getUnits()[1]:getPosition()
			local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
			local jammer_pos = Group.getByName(radar_data.jamming_params.jammer_name):getUnits()[1]:getPosition()
			local radar_jammed_sector = radar_data.jamming_params.radar_jammed_sector
			local elevation_on_target = catt.detect.get_elevation(radar_pos, target_pos)
			local elevation_on_jammer = catt.detect.get_elevation(radar_pos, jammer_pos)
			local elevation_min_max = {
					min = elevation_on_jammer + radar_jammed_sector.elevation[1],
					max = elevation_on_jammer + radar_jammed_sector.elevation[2], 
				}
			if elevation_on_target > elevation_min_max.min and elevation_on_target < elevation_min_max.max then
				local bearing_on_target = catt.meas.get_bearing(radar_pos, target_pos)
				local bearing_on_jammer = catt.meas.get_bearing(radar_pos, jammer_pos)
				local bearing_diff = bearing_on_target - bearing_on_jammer
				local jammed_azimuth_withd = (-1 * radar_jammed_sector.azimuth[1]) + radar_jammed_sector.azimuth[2]
				if bearing_diff < jammed_azimuth_withd then
					local jammer_distance = catt.meas.dist3d (jammer_pos.p, radar_pos.p)
					local target_distance = catt.meas.dist3d (target_pos.p, radar_pos.p)
					local radar_power = radar_data.specs.radar_power
					local jammer_power = radar_data.jamming_params.jammer_specs.radar_jammer_power
					local jammer_number = radar_data.jamming_params.jammers_employed
					local target_rcs = target_data.rcs 
					local jam_to_signal = ((jammer_power * jammer_number) / radar_power) * (math.pi * 4) * ((target_distance^4) / ((jammer_distance^2) * target_rcs))
					if jam_to_signal >= 1 then
						return 'yes'
					else
						return 'no'
					end    	
				else
					return 'no'
				end
			else
				return 'no'
			end
		else
			return 'no'
		end
    else
    	return 'no'
    end
end
    
	
	



function catt.detect.is_enemy_close(group_data, target_data)
	local group_pos = Group.getByName(group_data.group_name):getUnits()[1]:getPosition()
	local target_pos = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
	local distance = catt.meas.dist3d (group_pos.p, target_pos.p)
	if distance < 10 then 
		return 'yes'
	else 	
		return 'no'
	end
end



function catt.detect.is_already_in_table(group_data, target_data)
	local result = 'no'
	for id, value in pairs (group_data.picture) do
		if value.group_name == target_data.group_name then
			result = 'yes'
		end
	end
    return result
end
	
	
	
	
	
	

function catt.detect.insert_in_cop(obj_value)
    if obj_value.coalition == 'blue' then
		for contact_id, contact_value in pairs (obj_value.picture) do
		local is_present = 'no'
			for cop_cont_id, cop_cont_value in pairs (catt.detect.blue_cop) do
				if cop_cont_value.group_name == contact_value.group_name then
					is_present = 'yes'
				end
			end
        	if is_present == 'no' then
				table.insert(catt.detect.blue_cop, contact_value)
			end
         end
	elseif obj_value.coalition == 'red' then
		for contact_id, contact_value in pairs (obj_value.picture) do
		local is_present = 'no'
			for cop_cont_id, cop_cont_value in pairs (catt.detect.red_cop) do
				if cop_cont_value.group_name == contact_value.group_name then
					is_present = 'yes'
				end
			end
        	if is_present == 'no' then
				table.insert(catt.detect.red_cop, contact_value)
			end
         end
	end
end




function catt.detect.take_from_coal_picture(object_data, target_aquired)
	if object_data.coalition == 'blue' then
		for cop_contact_id, cop_contact_value in pairs (catt.detect.blue_cop) do
            if #target_aquired > 0 then
				for contact_id, contact_value in pairs (target_aquired) do
					if cop_contact_value.group_name ~= contact_value.group_name then
						table.insert(target_aquired, cop_contact_value)
					end
				end
          	else
                table.insert(target_aquired, cop_contact_value)
			end 
         end
	elseif  object_data.coalition == 'red' then
		for cop_contact_id, cop_contact_value in pairs (catt.detect.red_cop) do
            if #target_aquired > 0 then
				for contact_id, contact_value in pairs (target_aquired) do
					if cop_contact_value.group_name ~= contact_value.group_name then
						table.insert(target_aquired, cop_contact_value)
					end
				end
          	else
                table.insert(target_aquired, cop_contact_value)
			end 
         end
	end
end 
 






function catt.detect.is_comms_jammed(group_data)
	local result = 'no'
	for id, value in pairs (catt.ew.comms_jammed_list) do
		if value.group_name == group_data.group_name then
			result = 'yes'
		end
	end
    return result
end
 
 
 
 
 
function catt.detect.init()
	for obj_id, obj_value in pairs (catt.db.groups) do
		if obj_value.ato_mission then
			if obj_value.ato_mission.mission == 'awacs' then
				obj_value.last_pictures = {}
				obj_value.is_radar_active = 'yes'
				timer.scheduleFunction(catt.detect.gci_awacs_radar_sweep, obj_value, timer.getTime() + 2)
				timer.scheduleFunction(catt.detect.visual_sweep, obj_value, timer.getTime() + 2)
			elseif obj_value.ato_mission.mission == 'gci' then
				obj_value.last_pictures = {}
				obj_value.is_radar_active = 'yes'
				timer.scheduleFunction(catt.detect.gci_awacs_radar_sweep, obj_value, timer.getTime() + 2)			
			
			elseif obj_value.specs and obj_value.specs.has_air_radar and obj_value.specs.has_air_radar == 'yes' then
				obj_value.is_radar_active = 'yes'
				timer.scheduleFunction(catt.detect.radar_sweep, obj_value, timer.getTime() + 2)
				timer.scheduleFunction(catt.detect.visual_sweep, obj_value, timer.getTime() + 2)
			elseif obj_value.category == 'plane' or obj_value.category  == 'helicopter' then
				obj_value.is_radar_active = 'no'
				timer.scheduleFunction(catt.detect.visual_sweep, obj_value, timer.getTime() + 2)
			end
		end
	end

timer.scheduleFunction(catt.detect.cop_controller, nil, timer.getTime() + 1)
end



function catt.detect.cop_controller()
	catt.detect.blue_cop = {}
	catt.detect.red_cop = {}
	for obj_id, obj_value in pairs (catt.db.groups) do
		if obj_value.picture then
			if catt.detect.is_comms_jammed(obj_value) == 'no' then
				catt.detect.insert_in_cop(obj_value)
			end
		end  
	end
--trigger.action.outText('cop_controller is working', 1)	
return timer.getTime() + 15		
end



function catt.detect.radar_sweep(group_data)
    local group_name = group_data.group_name
		group_data.picture = {}
	if group_data.status == 'not engaged' then
		if catt.utils.is_active(group_name) == 'yes' then
			if group_data.is_radar_active == 'yes' then  -- ha un radar attivo
				for target_id, target_data in pairs (catt.db.groups) do
					local target_name = target_data.group_name
					if catt.utils.is_active(target_name) == 'yes' then
						if target_data.airborne == 'yes' then
							if target_data.coalition ~= group_data.coalition then
								if catt.detect.is_inside_scan_sector(group_data, target_data) == 'yes' then
									if catt.detect.is_in_los(group_data, target_data) == 'yes' then
										if catt.detect.is_in_range(group_data, target_data) == 'yes' then
											if catt.detect.has_ground_clutter(group_data, target_data) == 'no' then
											if catt.detect.is_radar_jammed(group_data, target_data) == 'no' then
												table.insert(group_data.picture, target_data)
												end
											end
										end
									end
								end      
							end
						end
					end
				end
			end	
		end
	end
	local radar_scan_period = group_data.specs.radar_scan_period
	if group_data.category == 'plane' or group_data.category  == 'helicopter' then
		local units_num = #group_data.group_units
		radar_scan_period = radar_scan_period / units_num
	end	
		
	if group_data.ato_mission.roe then
		catt.roe.evaluate_roe(group_data)
	end
	
--trigger.action.outText(group_name..' scan period: '..radar_scan_period..' seconds.', 2) 

return timer.getTime() + radar_scan_period	  
end




function catt.detect.visual_sweep(group_data)
	local group_name = group_data.group_name
		group_data.picture = {}
	if group_data.status == 'not engaged' then
--trigger.action.outText(group_name..' non è ingaggiato', 2) 

		if catt.utils.is_active(group_name) == 'yes' then
			for target_id, target_data in pairs (catt.db.groups) do
				if target_data.coalition ~= group_data.coalition then
					if catt.detect.is_enemy_close(group_data, target_data) == 'yes' then
						local target_name = target_data.group_name
						if catt.utils.is_active(target_name) == 'yes' then
							if target_data.airborne and target_data.airborne == 'yes' then
--trigger.action.outText(group_name..' vede '..target_data.group_name, 2) 
								
								--- MANCA ROUTINE DI DETECTION CHE DOVRA' 
								----- AVERE UN CALCOLO PROBABILISTICO
								----- TENER CONTO DELLA DISTANZA
								----- ESSERE FATTO PER TUTTI GLI AEREI NEL GRUPPO
								table.insert(group_data.picture, target_data)	
							end
						end
					end
				end
			end
		end
	end
	local visual_scan_period = 15
	
	if group_data.ato_mission.roe then
		catt.roe.evaluate_roe(group_data)
	end
return timer.getTime() + visual_scan_period	 
end



function catt.detect.gci_awacs_picture_info(picture)
	local sorted_picture = {}
	local new_picture = catt.utils.deep_copy(picture)
	for target_id, target_data in ipairs (new_picture) do
		local position = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
		local altitude = catt.conv.m_to_feet(position.p.y)
		local time_of_contact = timer.getAbsTime() 
		local data_table = {
			group_name = target_data.group_name,
			position = position,
			altitude = altitude,
			time_of_contact = time_of_contact,
		}
		table.insert(sorted_picture, data_table)
	end
return sorted_picture
end



function catt.detect.gci_awacs_picture_info(picture)
	local sorted_picture = {}
	local new_picture = catt.utils.deep_copy(picture)
	for target_id, target_data in ipairs (new_picture) do
		local position = Group.getByName(target_data.group_name):getUnits()[1]:getPosition()
		local altitude = catt.conv.m_to_feet(position.p.y)
		local time_of_contact = timer.getAbsTime() 
		local data_table = {
			group_name = target_data.group_name,
			position = position,
			altitude = altitude,
			time_of_contact = time_of_contact,
		}
		table.insert(sorted_picture, data_table)
	end
return sorted_picture
end



function catt.detect.gci_awacs_radar_sweep(group_data)
    local group_name = group_data.group_name
		group_data.picture = {}
	if group_data.status == 'not engaged' then
		if catt.utils.is_active(group_name) == 'yes' then
			if group_data.is_radar_active == 'yes' then  -- ha un radar attivo
				for target_id, target_data in pairs (catt.db.groups) do
					local target_name = target_data.group_name
					if catt.utils.is_active(target_name) == 'yes' then
						if target_data.airborne == 'yes' then
							if target_data.coalition ~= group_data.coalition then
								if catt.detect.is_inside_scan_sector(group_data, target_data) == 'yes' then
                                    if catt.detect.is_in_los(group_data, target_data) == 'yes' then
										if catt.detect.is_in_range(group_data, target_data) == 'yes' then

											if catt.detect.has_ground_clutter(group_data, target_data) == 'no' then
											if catt.detect.is_radar_jammed(group_data, target_data) == 'no' then

												table.insert(group_data.picture, target_data)
												end
											end
										end
									end
								end      
							end
						end
					end
				end
			end	
		end
	end
	local radar_scan_period = group_data.specs.radar_scan_period
	if group_data.category == 'plane' or group_data.category  == 'helicopter' then
		local units_num = #group_data.group_units
		radar_scan_period = radar_scan_period / units_num
	end	
		
	if group_data.ato_mission.roe then
		catt.roe.evaluate_roe(group_data)
	end
	
	local new_picture = catt.detect.gci_awacs_picture_info(group_data.picture)
	table.insert(group_data.last_pictures, 1, new_picture)
	if #group_data.last_pictures > 4 then
		group_data.last_pictures[5] = nil
	end
	
return timer.getTime() + radar_scan_period	  
end

------------------------------------------  ROE  ------------------------------------------




catt.roe = {}



					
function catt.roe.targeting(object_data, roe_table)
	local target_threat = {}
	for roe_id, roe_data in ipairs (roe_table) do	    
		if roe_data.type == 'proximity' then
			local target_set = catt.roe.proximity_check(object_data, roe_data)
			for contact_id, contact_value in pairs (target_set) do
				table.insert(target_threat, contact_value)
			end
		elseif roe_data.type == 'zone' then
			local target_set = catt.roe.zone_check(object_data, roe_data)
			for contact_id, contact_value in pairs (target_set) do
				table.insert(target_threat, contact_value)
			end
		elseif roe_data.type == 'protection' then
			local target_set = catt.roe.protection_check(object_data, roe_data)
			for contact_id, contact_value in pairs (target_set) do
				table.insert(target_threat, contact_value)
			end
		end
	end		
	return target_threat
end



--
--[1] = {
--	type = 'proximity',
--	distance = 20,
--},
--			
--
--
--[1] = {
--	type = 'zone',
--	zone_name = 'fez01',
--},
--[1] = {
--	type = 'protection',
--	protect_group_name = 'wizard',
--	distance = 30,
--},
	
	
		
function catt.roe.protection_check(object_data, roe_data)
    local target_threat = {}
	local protect_group_name = roe_data.protect_group_name
--trigger.action.outText('works', 4)	
	if object_data.status == 'not engaged' then
		local target_aquired = catt.utils.deep_copy(object_data.picture) --copia i dati della picture
		if catt.detect.is_comms_jammed(object_data) == 'no' then --verifica se ha comms jammato
			catt.detect.take_from_coal_picture(object_data, target_aquired)
		end
		if catt.utils.is_active(protect_group_name) == 'yes' then
			local protect_group_pos = Group.getByName(protect_group_name):getUnits()[1]:getPosition()
			for target_id, target_value in pairs (target_aquired) do
				local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
				local distance = catt.meas.dist2d(protect_group_pos.p, target_pos.p)
				if distance < roe_data.distance then
--trigger.action.outText(object_data.group_name..' può ingaggiare '..target_value.group_name, 4)	
					table.insert (target_threat, target_value)
				else
--trigger.action.outText('distance: '..distance, 4)	
                end
                
			end
		end
		
	elseif object_data.status == 'engaged' then -- controlla su tutto il db
		if catt.utils.is_active(protect_group_name) == 'yes' then
			local protect_group_pos = Group.getByName(protect_group_name):getUnits()[1]:getPosition()
			for target_id, target_value in pairs (catt.db.groups) do
				if target_value.coalition ~= object_data.coalition then
					if catt.utils.is_active(target_value.group_name) == 'yes' then
						if target_value.airborne and target_value.airborne == 'yes' then
							local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
							local distance = catt.meas.dist2d(protect_group_pos.p, target_pos.p)
							if distance < roe_data.distance then
								table.insert (target_threat, target_value)
--trigger.action.outText(object_data.group_name..' continua ad ingaggiare '..target_value.group_name, 4)
							end
						end
					end	
				end
			end
		end
	end	
return target_threat
end


	
function catt.roe.zone_check(object_data, roe_data)
	local target_threat = {}
--trigger.action.outText('works', 5)
	local counter = 0
	local zone_data = catt.c2.get_acm(roe_data.zone_name)
	local zone_points = zone_data.points
	local zone_altitude
	if zone_data.altitude then
		zone_altitude = zone_data.altitude
	else 
		zone_altitude = {0, 60000}
	end
	
	if object_data.status == 'not engaged' then
--trigger.action.outText(object_data.group_name..' is not engaged', 5) 
		local target_aquired = catt.utils.deep_copy(object_data.picture) --copia i dati della picture
		if catt.detect.is_comms_jammed(object_data) == 'no' then --verifica se ha comms jammato
			catt.detect.take_from_coal_picture(object_data, target_aquired)
		end
--trigger.action.outText(mist.utils.tableShow(zone_points), 5)

		for target_id, target_value in pairs (target_aquired) do
			local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
			if catt.utils.check_point_in_zone(target_pos.p, zone_points, zone_altitude) == true then
--trigger.action.outText(target_value.group_name..' is inside fez', 5)			
                counter = counter + 1
			end
			if counter > 0 then
				table.insert (target_threat, target_value)
			else
--trigger.action.outText(target_value.group_name..' is not inside fez', 5)
            end

		end

    elseif object_data.status == 'engaged' then -- controlla su tutto il db      
--trigger.action.outText(object_data.group_name..' is engaged', 5)
		for target_id, target_value in pairs (catt.db.groups) do
			if target_value.coalition ~= object_data.coalition then
				if catt.utils.is_active(target_value.group_name) == 'yes' then
					if target_value.airborne and target_value.airborne == 'yes' then
						local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
						if catt.utils.check_point_in_zone(target_pos.p, zone_points, zone_altitude) == true then
							counter = counter + 1
						end
						if counter > 0 then
							table.insert (target_threat, target_value)
						end
					end
				end	
			end
		end
	end	
return target_threat
end



function catt.roe.proximity_check(object_data, roe_data)
    local target_threat = {}
--trigger.action.outText(object_data.group_name..' works', 4)	
    if object_data.status == 'not engaged' then
--trigger.action.outText(object_data.group_name..' is not engaged', 4)		
		local target_aquired = catt.utils.deep_copy(object_data.picture) --copia i dati della picture
		if catt.detect.is_comms_jammed(object_data) == 'no' then --verifica se ha comms jammato
			catt.detect.take_from_coal_picture(object_data, target_aquired)
		end
		for target_id, target_value in pairs (target_aquired) do
			local obj_pos = Group.getByName(object_data.group_name):getUnits()[1]:getPosition()
			local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
			local distance = catt.meas.dist2d(obj_pos.p, target_pos.p)
			if distance < roe_data.distance then
--trigger.action.outText(object_data.group_name..' può ingaggiare '..target_value.group_name, 4)	
				table.insert (target_threat, target_value)
			end
		end
		
	elseif object_data.status == 'engaged' then -- controlla su tutto il db
--trigger.action.outText(object_data.group_name..' is engaged', 4)		
		for target_id, target_value in pairs (catt.db.groups) do
			if target_value.coalition ~= object_data.coalition then
				if catt.utils.is_active(target_value.group_name) == 'yes' then
					if target_value.airborne and target_value.airborne == 'yes' then
						local obj_pos = Group.getByName(object_data.group_name):getUnits()[1]:getPosition()
						local target_pos = Group.getByName(target_value.group_name):getUnits()[1]:getPosition()
						local distance = catt.meas.dist2d(obj_pos.p, target_pos.p)
						if distance < roe_data.distance then
							table.insert (target_threat, target_value)
--trigger.action.outText(object_data.group_name..' continua ad ingaggiare '..target_value.group_name, 4)
						end
					end
				end	
			end
		end
	end	
return target_threat
end



function catt.detect.force_acquisition(object_name, target_threat)
	local group_units = Group.getByName(object_name):getUnits()
    for unit_id, unit_value in pairs (group_units) do
	    local ctr = unit_value:getController()
        for target_group_id, target_group_value in pairs (target_threat) do 
            local target_group_name = target_group_value.group_name
            local target_units = Group.getByName(target_group_name):getUnits()
            for target_unit_id, target_unit_value in pairs (target_units) do
                ctr:knowTarget(target_unit_value)
            end
      	end
 	end  
end

    			
		
function catt.roe.evaluate_roe(object_data)
	local object_name = object_data.group_name
	local roe_table = object_data.ato_mission.roe
	local target_threat = catt.roe.targeting(object_data, roe_table)
	if object_data.status == 'not engaged' then
		
		if #target_threat > 0 then
			catt.tasker.option_script(object_name, 'roe', 'free')
			object_data.status = 'engaged' 
			catt.detect.force_acquisition(object_name, target_threat)
		else
			catt.tasker.option_script(object_name, 'roe', 'tight')
--trigger.action.outText(object_name..' non ha target validi', 4)	
		end
	elseif object_data.status == 'engaged' then
		if #target_threat == 0 then
			catt.tasker.option_script(object_name, 'roe', 'tight')
			object_data.status = 'not engaged' 
--trigger.action.outText(object_name..' ha terminato il ingaggio', 4)	

		end
	end
end



------------------------------------------  CHECKER  ------------------------------------------

--catt.checker = {}
--
--catt.checker.low_freq_list = {}
--
--function catt.checker.exec_action(action)
--	if action.type == 'set_leg' then
--		catt.tasker.set_leg(action.group_data, action.leg_number)
--	end
--	if action.type == 'set_hold' then
--		catt.tasker.set_hold(action.group_data, action.leg_number)
--	end
--end


------------------------------------------  TASKER  ------------------------------------------

catt.tasker = {}




function catt.tasker.set_leg(group_mission, leg_number)
	local active_leg = group_mission.route[leg_number]
	if active_leg.type == 'nav' then 
		catt.tasker.fly_to(group_mission, leg_number)
		group_mission.mission_state = {}
			group_mission.mission_state.state = 'enroute'
			group_mission.mission_state.way_point_number = leg_number
			group_mission.mission_state.way_point_name = active_leg.point			
			group_mission.mission_state.turning_distance = catt.tasker.get_turning_distance(group_mission, leg_number)
		
	elseif active_leg.type == 'cap' or active_leg.type == 'hold' then
		catt.tasker.hold(group_mission, leg_number)
		group_mission.mission_state = {}
			group_mission.mission_state.state = 'enroute_to_holding'
			group_mission.mission_state.way_point_number = leg_number
			group_mission.mission_state.way_point_name = active_leg.point	
			
	elseif active_leg.type == 'rtb' then
		catt.tasker.fly_to(group_mission, leg_number)
		group_mission.mission_state = {}
			group_mission.mission_state.state = 'rtb'
			group_mission.mission_state.airport_name = active_leg.rtb_vars.airport_name
			group_mission.mission_state.procedure_name = active_leg.rtb_vars.procedure_name
	
	--elseif active_leg.type == 'land_straight_in' then
		--catt.tasker.land_straight_in(group_mission, leg_number)
	end
end



function  catt.tasker.get_turning_distance(group_mission, leg_number)
	if group_mission.route[leg_number + 1] then
		local current_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
		local current_wp_point = catt.aco.get_nav_fix_by_name(group_mission.route[leg_number].point)
		local next_wp_point = catt.aco.get_nav_fix_by_name(group_mission.route[leg_number + 1].point)
		local current_course = catt.meas.get_bearing_with_points(current_point, current_wp_point)
		local next_course = catt.meas.get_bearing_with_points(current_wp_point, next_wp_point)
		local course_diff = math.abs(current_course - next_course)
		local speed = group_mission.route[leg_number].speed
		local speed_factor = speed / 480
		local turning_distance 
		if course_diff < 45 then
			turning_distance = 2 * speed_factor
		elseif course_diff > 45 and course_diff < 90 then
			turning_distance = 3 * speed_factor
		elseif course_diff > 90 then
			turning_distance = 5 * speed_factor
		end
		return turning_distance
	else 
	return 1
	end
end    

  



function catt.tasker.fly_to(group_mission, leg_number)
    local group = Group.getByName(group_mission.group_name)
    local active_leg = group_mission.route[leg_number]
	local way_point_name = active_leg.point
    local way_point_point = catt.aco.get_nav_fix_by_name(way_point_name)
		local way_point = {
			type = 'Turning Point', 
			action = 'Turning Point',
			x = way_point_point.x, 
			y = way_point_point.z, 
			alt = catt.conv.feet_to_m(active_leg.altitude), 
			alt_type = active_leg.alt_type,
			task = {
				id = "ComboTask",
				params = {
					tasks = {}, -- end of tasks
				}, -- end of params
			}, -- end of task 
		}
    	way_point.speed_locked = true
		way_point.speed = catt.conv.kts_to_ms(active_leg.speed)
    	
		local mission = {
		id = 'Mission', 
		params = {
			route = {
				points = {                  
					},
				},
			},
		}	
    	table.insert(mission.params.route.points, way_point)
    	group:getController():setTask(mission)
			
end









function catt.tasker.hold(group_mission, leg_number)
--- si dirige prima verso il punto arretrato costruito dalla funzione stessa  
--- e successivamente verso il punto avanzato (point di riferimento) 

    local group = Group.getByName(group_mission.group_name)
    local active_leg = group_mission.route[leg_number]
	local way_point_name = active_leg.point
    local forward_way_point_point = catt.aco.get_nav_fix_by_name(active_leg.point)

		local forward_way_point = {
			type = 'Turning Point', 
			action = 'Turning Point',
			x = forward_way_point_point.x, 
			y = forward_way_point_point.z, 
			alt = catt.conv.feet_to_m(active_leg.altitude), 
			alt_type = active_leg.alt_type,
			task = {
				id = "ComboTask",
				params = {
					tasks = {}, -- end of tasks
				}, -- end of params
			}, -- end of task 
		}
    
    	forward_way_point.speed_locked = true
		forward_way_point.speed = catt.conv.kts_to_ms(active_leg.speed)
    	
	local angle = catt.utils.round_angle(active_leg.hold_param.direction + 180)
	local direction_uni_vector = catt.vector.angle_to_vector(angle)
	local direction_vector = catt.vector.vector_scaling(direction_uni_vector, (active_leg.hold_param.length * 1852))
	local rear_way_point_point = catt.vector.add(forward_way_point_point, direction_vector)
		
		local rear_way_point = {
			type = 'Turning Point', 
			action = 'Turning Point',
			x = rear_way_point_point.x, 
			y = rear_way_point_point.z, 
			alt = catt.conv.feet_to_m(active_leg.altitude), 
			alt_type = active_leg.alt_type,
			task = {
				id = "ComboTask",
				params = {
					tasks = {
						[1] = {
							enabled = true,
							auto = false,
							id = "Orbit",
							number = 1,
							params = {
								altitude = catt.conv.feet_to_m(active_leg.hold_param.altitude),
								pattern = "Race-Track",
								speed = catt.conv.kts_to_ms(active_leg.hold_param.speed),
							}, -- end of params
						}, -- end of task
					
					}, -- end of tasks
				}, -- end of params
			}, -- end of task 
		}
    
    	rear_way_point.speed_locked = true
		rear_way_point.speed = catt.conv.kts_to_ms(active_leg.speed)
	
    	local mission = {
		id = 'Mission', 
		params = {
			route = {
				points = {                  
					},
				},
			},
		}	
		
   	table.insert(mission.params.route.points, rear_way_point)
   	table.insert(mission.params.route.points, forward_way_point)

   	group:getController():setTask(mission)		

end





function catt.tasker.controller()
	for group_id, group_value in pairs (catt.db.groups) do
		if not group_value.is_player then
			if group_value.ato_mission and group_value.ato_mission.route then
				if Group.getByName(group_value.group_name):getUnits()[1] and catt.utils.is_active(group_value.group_name) == 'yes'then
					local group_mission = group_value.ato_mission
					if group_mission.mission_state.state == 'airborne' then
						
						catt.tasker.set_leg(group_mission, 1)
					
	-----------	runway					
					elseif group_mission.mission_state.state == 'runway' then
						group_mission.mission_state.state = 'waiting_dep_clearance'
						catt.atc.insert_in_departure(group_value)
	-----------	ramp					
					elseif group_mission.mission_state.state == 'ramp' then
					
					
					
	-----------	enroute					
					elseif group_mission.mission_state.state == 'enroute' then
	--trigger.action.outText('enroute', 5)
	
						local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
						local wp_point = catt.aco.get_nav_fix_by_name(group_mission.mission_state.way_point_name)
						local turning_distance = group_mission.mission_state.turning_distance
						local leg_number = group_mission.mission_state.way_point_number 
						local distance = catt.meas.dist2d (group_point, wp_point)
						if distance < turning_distance then
							
	--trigger.action.outText('ok', 5)
							catt.tasker.set_leg(group_mission, leg_number + 1)
						else
	--trigger.action.outText('no', 5)
	
						end
						
	-----------	enroute_to_holding					
					elseif group_mission.mission_state.state == 'enroute_to_holding' then
	--trigger.action.outText('enroute_to_holding', 5) 
						local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
						local wp_point = catt.aco.get_nav_fix_by_name(group_mission.mission_state.way_point_name)
						local leg_number = group_mission.mission_state.way_point_number 
						local distance = catt.meas.dist2d (group_point, wp_point)
	--trigger.action.outText('distance: '..distance, 5)
	--trigger.action.outText('holding_minutes: '..group_mission.route[leg_number].hold_param.holding_minutes * 60, 5)
						if distance < 2 then
	--trigger.action.outText('ok', 5)
							group_mission.mission_state = {} 
								group_mission.mission_state.state = 'holding'
								group_mission.mission_state.way_point_number = leg_number
								group_mission.mission_state.way_point_name = group_mission.route[leg_number].point
								
	
							if group_mission.route[leg_number].hold_param.holding_minutes then
								group_mission.mission_state.stop_holding = timer:getTime() + (group_mission.route[leg_number].hold_param.holding_minutes * 60)
							elseif group_mission.route[leg_number].hold_param.hold_until then
								local end_time = catt.conv.dhms_to_abs(group_mission.route[leg_number].hold_param.hold_until) 
								group_mission.mission_state.stop_holding = end_time - timer.getTime0()
							end
						else
	--trigger.action.outText('no', 5)
						end
						
	-----------	holding					
					elseif group_mission.mission_state.state == 'holding' then
	--trigger.action.outText('holding', 5)
	
						local leg_number = group_mission.mission_state.way_point_number 
	--trigger.action.outText('timer:getTime(): '..timer:getTime(), 5)
	--trigger.action.outText('stop_holding: '..group_mission.mission_state.stop_holding, 5)
	
						if timer:getTime() > group_mission.mission_state.stop_holding then
	--trigger.action.outText('ok', 5)
	
							catt.tasker.set_leg(group_mission, leg_number + 1)
						else
	--trigger.action.outText('no', 5)
	
						end
	-----------	rtb					
					elseif group_mission.mission_state.state == 'rtb' then
					group_mission.mission_state.state = 'waiting_arr_clearance'
	--trigger.action.outText('waiting_arr_clearance', 5)
					catt.atc.insert_in_approach(group_value)
					end
				end
				
			end	
		end
	end	
	
return timer.getTime() + 3	 
end







------------------------------------------  ATC  ------------------------------------------

catt.atc = {}





function catt.atc.insert_in_departure(group_value)
	local airport_name = group_value.ato_mission.mission_state.airport_name
	for ab_id, ab_value in pairs (aco.airbases) do
		if ab_id == airport_name then
			table.insert(ab_value.departure, group_value)
		end
	end
end


function catt.atc.insert_in_approach(group_value)
	local airport_name = group_value.ato_mission.mission_state.airport_name
	for ab_id, ab_value in pairs (aco.airbases) do
		if ab_id == airport_name then
			table.insert(ab_value.arrival, group_value)
		end
	end
end



function catt.atc.get_procedure(procedure_name, rwy_in_use)
	for ab_id, ab_value in pairs (aco.airbases) do
		if ab_value.procedures[rwy_in_use] then
			for proc_id, proc_value in pairs (ab_value.procedures[rwy_in_use]) do
				if proc_value.name == procedure_name then
					return proc_value
				end
			end
		end
	end	
end



function  catt.atc.get_turning_distance(group_mission, procedure, leg_number)
	if procedure.route[leg_number + 1] then
		local current_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
		local current_wp_point = catt.aco.get_nav_fix_by_name(procedure.route[leg_number].point)
		local next_wp_point = catt.aco.get_nav_fix_by_name(procedure.route[leg_number + 1].point)
		local current_course = catt.meas.get_bearing_with_points(current_point, current_wp_point)
		local next_course = catt.meas.get_bearing_with_points(current_wp_point, next_wp_point)
		local course_diff = math.abs(current_course - next_course)
		local speed = procedure.route[leg_number].ias
		local speed_factor = speed / 480
		local turning_distance 
		if course_diff < 45 then
			turning_distance = 1.5 * speed_factor
		elseif course_diff > 45 and course_diff < 90 then
			turning_distance = 2 * speed_factor
		elseif course_diff > 90 then
			turning_distance = 4 * speed_factor
		end
		return turning_distance
	else 
	return 1.5
	end
end    




function catt.atc.fly_to(group_mission, procedure, leg_number)
    local group = Group.getByName(group_mission.group_name)
    local active_leg = procedure.route[leg_number]
	local way_point_name = active_leg.point
    local way_point_point = catt.aco.get_nav_fix_by_name(way_point_name)
		local way_point = {
			type = 'Turning Point', 
			action = 'Turning Point',
			x = way_point_point.x, 
			y = way_point_point.z, 
			alt = catt.conv.feet_to_m(active_leg.altitude), 
			alt_type = 'BARO',
			task = {
				id = "ComboTask",
				params = {
					tasks = {}, -- end of tasks
				}, -- end of params
			}, -- end of task 
		}
    	way_point.speed_locked = true
		way_point.speed = catt.conv.kts_to_ms(catt.conv.ias_to_gs(active_leg.ias, active_leg.altitude))

    	
		local mission = {
		id = 'Mission', 
		params = {
			route = {
				points = {                  
					},
				},
			},
		}	
    	table.insert(mission.params.route.points, way_point)
    	group:getController():setTask(mission)
			
end







function catt.atc.land(group_mission, ab_value, procedure, leg_number)	
    local group = Group.getByName(group_mission.group_name)
    local active_leg = procedure.route[leg_number]
	local way_point_name = active_leg.point
	local way_point_point = catt.aco.get_nav_fix_by_name(way_point_name)
	local altitude = catt.conv.feet_to_m(active_leg.altitude - 2500)
	local speed = catt.conv.kts_to_ms(200)

trigger.action.outText('ab_value: '..ab_value.id, 35)
trigger.action.outText('altitude: '..altitude, 35)

	local way_point = {
		type = 'Land', 
		action = 'Landing',
		airdromeId = ab_value.id,
		x = way_point_point.x, 
		y = way_point_point.z, 
		alt = altitude, 
		alt_type = 'BARO',
		speed_locked = true,
		speed = speed,
		task = {
			id = "ComboTask",
			params = {
				tasks = {}, -- end of tasks
			}, -- end of params
		}, -- end of task 
	}
			
			
	local mission = {
		id = 'Mission', 
		params = {
		route = {
			points = {                  
				},
			},
		},
	}	
	
	table.insert(mission, way_point)
    group:getController():setTask(mission)
	

end




--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
















function catt.atc.fly_dep_procedure(group_mission, procedure)
	local group = Group.getByName(group_mission.group_name)
	local group_point = group:getUnits()[1]:getPoint()
	local final_destination = procedure.final_destination
	local mission = {
		id = 'Mission', 
		params = {
			route = {
				points = { 
					[1] = {
						type = 'Turning Point', 
						action = 'Turning Point',
						x = group_point.x, 
						y = group_point.z, 
						alt = group_point.y, 
						alt_type = 'BARO',
						speed = 250,
						speed_locked = true,
						task = {
							id = "ComboTask",
							params = {
								tasks = {}, -- end of tasks
							}, -- end of params
						}, -- end of task 
					},	
				},
			},
		},
	}	
	
	for point_id, point_value in ipairs (procedure.route) do
		local way_point_name = point_value.point
--trigger.action.outText(catt.aco.get_nav_fix_by_name(way_point_name), 5)
        local way_point_point = catt.aco.get_nav_fix_by_name(way_point_name)
		
		local way_point = {
			type = 'Turning Point', 
			action = 'Turning Point',
			x = way_point_point.x, 
			y = way_point_point.z, 
			alt = catt.conv.feet_to_m(point_value.altitude), 
			alt_type = 'BARO',
			task = {
				id = "ComboTask",
				params = {
					tasks = {}, -- end of tasks
				}, -- end of params
			}, -- end of task 
		}
    	way_point.speed_locked = true
		way_point.speed = catt.conv.kts_to_ms( catt.conv.ias_to_gs(point_value.ias, point_value.altitude)) ----- DA METTERE IN GS
    	
		
    	table.insert(mission.params.route.points, way_point)
    end	
	
	group:getController():setTask(mission)
	
	group_mission.mission_state = {}
		group_mission.mission_state.state = 'departure_cleared'
		group_mission.mission_state.way_point_name = final_destination			
		
end







function catt.atc.controller()
	for ab_id, ab_value in pairs (aco.airbases) do
		---- DEPARTURE 
		if #ab_value.departure > 0 then
			local rwy_in_use = ab_value.atc.rwy_in_use
			for group_id, group_value in pairs (ab_value.departure) do
				local group_mission = group_value.ato_mission
				if group_mission.mission_state.state == 'waiting_dep_clearance' then
					local procedure_name = group_mission.mission_state.procedure_name
					local procedure = catt.atc.get_procedure(procedure_name, rwy_in_use)
--trigger.action.outText(mist.utils.tableShow(procedure), 5)
--trigger.action.outText(procedure_name, 5)

					catt.atc.fly_dep_procedure(group_mission, procedure)
				elseif group_mission.mission_state.state == 'departure_cleared' then
                    local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
					local wp_point = catt.aco.get_nav_fix_by_name(group_mission.mission_state.way_point_name)
                    local distance = catt.meas.dist2d (group_point, wp_point)
                    if distance < 3 then
                        group_mission.mission_state.state = 'airborne'
                        group_value = {}
--trigger.action.outText(mist.utils.tableShow(group_mission.mission_state), 5)
--trigger.action.outText(distance, 5)
                        
                        
                   end
                    
                end 
			end
		end
						
				
		---- ARRIVAL
		if #ab_value.arrival > 0 then
			local rwy_in_use = ab_value.atc.rwy_in_use
			local airbase_point = {x = ab_value.x, z = ab_value.z}
			for group_id, group_value in pairs (ab_value.arrival) do
				local group_mission = group_value.ato_mission
				
				---- waiting_arr_clearance
				if group_mission.mission_state.state == 'waiting_arr_clearance' then 
--trigger.action.outText(group_mission.group_name..' waiting_arr_clearance', 5)
					local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
					local distance = catt.meas.dist2d (group_point, airbase_point)
--trigger.action.outText('distance: '..distance, 5)

					if distance < 40 + (math.random() * 20) then 
						local procedure_name = group_mission.mission_state.procedure_name
						local procedure = catt.atc.get_procedure(procedure_name, rwy_in_use) 
						catt.atc.fly_to(group_mission, procedure, 1)
						group_mission.mission_state = {}
							group_mission.mission_state.state = 'enroute_to_iaf'
							group_mission.mission_state.procedure = procedure	
					end
				---- enroute_to_iaf
				elseif group_mission.mission_state.state == 'enroute_to_iaf' then
--trigger.action.outText(group_mission.group_name..' enroute_to_iaf', 5)
--trigger.action.outText(group_mission.mission_state.procedure.route[1].point, 5)

                    
					local procedure = group_mission.mission_state.procedure
					local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
					local wp_name = group_mission.mission_state.procedure.route[1].point
					local wp_point = catt.aco.get_nav_fix_by_name(wp_name)
					local turning_distance = catt.atc.get_turning_distance(group_mission, procedure, 1)
					local leg_number = 1
					local distance = catt.meas.dist2d (group_point, wp_point)
--trigger.action.outText('distance: '..distance, 5)
--trigger.action.outText('turning_distance: '..turning_distance, 5)
					if distance < turning_distance then
					---- inserire hold qui
					---- inserire hold qui
					---- inserire hold qui
					---- inserire hold qui
					---- inserire hold qui
						if #procedure.route > 2 then
							catt.atc.fly_to(group_mission, procedure, leg_number + 1)			
								group_mission.mission_state.state = 'cleared_approach'
								group_mission.mission_state.way_point_number = leg_number + 1
						else
							catt.atc.fly_to(group_mission, procedure, leg_number + 1)			
								group_mission.mission_state.state = 'enroute_to_faf'
								group_mission.mission_state.way_point_number = leg_number + 1
						end
					
					end
				---- cleared_approach
				elseif group_mission.mission_state.state == 'cleared_approach' then
--trigger.action.outText(group_mission.group_name..' cleared_approach', 5)
					local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
					local leg_number = group_mission.mission_state.way_point_number
					local procedure = group_mission.mission_state.procedure
                    local wp_name = procedure.route[leg_number].point
					local wp_point = catt.aco.get_nav_fix_by_name(wp_name)
--trigger.action.outText(leg_number..' leg_number', 5)
					local turning_distance = catt.atc.get_turning_distance(group_mission, procedure, leg_number)
					local distance = catt.meas.dist2d (group_point, wp_point)
--trigger.action.outText('distance: '..distance, 5)
--trigger.action.outText('turning_dissstance: '..turning_distance, 5)                

					if distance < turning_distance then
						if group_mission.mission_state.procedure.route[leg_number + 2] then
--trigger.action.outText(group_mission.group_name..' cleared_approach', 5)
--trigger.action.outText(group_mission.group_name..' going to wp '..(leg_number + 1), 5)
							catt.atc.fly_to(group_mission, procedure, leg_number + 1)			
								group_mission.mission_state.state = 'cleared_approach' 
								group_mission.mission_state.way_point_number = leg_number + 1
						else 
--trigger.action.outText(group_mission.group_name..' enroute_to_faf', 5)

							catt.atc.fly_to(group_mission, procedure, leg_number + 1)			
								group_mission.mission_state.state = 'enroute_to_faf'
								group_mission.mission_state.way_point_number = leg_number + 1
                            
						end
                	end

				---- enroute_to_faf
				elseif group_mission.mission_state.state == 'enroute_to_faf' then
--trigger.action.outText(group_mission.group_name..' enroute_to_faf', 5)
					local group_point = Group.getByName(group_mission.group_name):getUnits()[1]:getPoint()
					local leg_number = group_mission.mission_state.way_point_number
					local procedure = group_mission.mission_state.procedure
                    local wp_name = procedure.route[leg_number].point
					local wp_point = catt.aco.get_nav_fix_by_name(wp_name)
--trigger.action.outText(leg_number..' leg_number', 5)
--trigger.action.outText(mist.utils.tableShow(wp_point), 5)
					local turning_distance = 2
					local distance = catt.meas.dist2d (group_point, wp_point)
--trigger.action.outText('distance: '..distance, 5)
--trigger.action.outText('turning_dissstance: '..turning_distance, 5)                
--trigger.action.outText('ab_value: '..ab_value.id, 5)                

					if distance < turning_distance then
						catt.atc.land(group_mission, ab_value, procedure, leg_number)			
						group_mission.mission_state.state = 'landing'
					end
				end
			end	
		end
	end
		
		
return timer.getTime() + 3	 
end






------------------------------------------  PLAYER  ------------------------------------------

catt.player = {}

function catt.player.init()
	for group_id, group_value in pairs (catt.db.groups) do
        if catt.utils.is_group_player(group_value.group_name) == 'yes' then 
            group_value.is_player = 'yes'
            --catt.player.controller(group_value)
       	end 
   	end
end


function catt.player.abort_approach(group_value)
	group_value.ato_mission.mission_state = {}
	group_value.ato_mission.mission_state.state = 'airborne'
end 

  
function catt.player.passed_to_final_controller(group_value)   
	group_value.ato_mission.mission_state.state = 'contacting_final_controller'    
end 



function catt.player.select_closest_airbases(group_name)
    local group_point = Group.getByName(group_name):getUnits()[1]:getPoint()
   	local all_airbases = {} 
    for ab_id, ab_value in pairs (aco.airbases) do
		local entry = catt.utils.deep_copy(ab_value)
        	entry.name = ab_id
        table.insert(all_airbases, entry)
	end
    for ab_id, ab_value in pairs (all_airbases) do
			local ab_point = {x=ab_value.x, z=ab_value.z}
    	    	ab_value.distance = catt.meas.dist2d(group_point, ab_point)
   	end     
    local sorted_table = catt.utils.sort_table(all_airbases, 'name', 'distance', 'lower', 10)
return sorted_table
end







function catt.player.get_rwy_separation_and_base(group_mission)
	local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
    local ab_point = group_mission.mission_state.ab_value
    local ab_distance = catt.meas.dist2d(player_pos.p, ab_point)
    local bear = math.rad(catt.meas.get_bearing_with_points(ab_point, player_pos.p) - options.mag_var)
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading
    local rwy_opp = math.rad(catt.utils.round_angle(rwy_heading - 180))
    local aspect =  bear - rwy_opp
	if aspect > 2 * math.pi then
		aspect = aspect - (2 * math.pi)
	end
	if aspect < 0 then
		aspect = aspect + (2 * math.pi)
	end
    local separation = math.abs(ab_distance * math.sin(aspect))
    local base = math.abs(ab_distance * math.cos(aspect))
return separation, base
end




function catt.player.get_radio_callsign(callsign)
	local callsign_table = {}
	local word = string.sub(callsign, string.find (callsign, '%a+'))
		callsign_table[#callsign_table + 1] = word
	local capital_word = string.gsub(word, '^%l', string.upper)
	if string.find (callsign, '%d+') then
		local number = string.sub(callsign, string.find (callsign, '%d+'))        
		local number_count = string.len(number)
		if  number_count > 1 then
			local first_num = string.sub(number, 1, 1)
			local second_num = string.sub(number, -1)
			callsign_table[#callsign_table + 1] = first_num
			callsign_table[#callsign_table + 1] = second_num
		else
			callsign_table[#callsign_table + 1] = number
		end
	end
return capital_word, callsign_table
end






function catt.player.set_approach(appr_data)
	local appr_type = appr_data.appr_type
	local group_value = appr_data.group_value
	local proc_value = appr_data.proc_value
	local ab_value = appr_data.ab_value
	group_value.ato_mission.mission_state = {}
	group_value.ato_mission.mission_state.state = 'requesting_approach'
	group_value.ato_mission.mission_state.appr_type = appr_type
	group_value.ato_mission.mission_state.proc_value = proc_value
	group_value.ato_mission.mission_state.ab_value = ab_value
	if appr_data.vectors_approach then
		group_value.ato_mission.mission_state.vectors_approach = appr_data.vectors_approach
	end
end






function catt.player.radio_menu_controller(group_value)	
	local player_unit = Group.getByName(group_value.group_name):getUnits()[1]
		---- INSTALL APPROACH MENU
		if group_value.ato_mission.mission_state.state == 'airborne' then 
			if not catt.player.is_appr_menu_installed then
				catt.player.is_appr_menu_installed = 'no'
			end
        
			if catt.player.is_appr_menu_installed == 'no' then
				missionCommands.removeItem('APPROACH')
				catt.player.is_appr_menu_installed = 'yes'
--trigger.action.outText('arriva', 5)
				local appr_menu = missionCommands.addSubMenu("APPROACH"					, nil								)
				local closest_ab = catt.player.select_closest_airbases(group_value.group_name)
				for ab_id, ab_value in ipairs (closest_ab) do
					if ab_value.atc then 
						if ab_value.procedures then
						local menu = missionCommands.addSubMenu(ab_value.name..' ('..ab_value.appr_freq..' Mhz)'				, appr_menu							)
							for rwy_id, rwy_value in pairs (ab_value.procedures) do
								if rwy_id == ab_value.atc.rwy_in_use then
									--- aggiungi altre procedure
									--- aggiungi altre procedure
									--- aggiungi altre procedure
                               
									
									
									for proc_id, proc_value in pairs (ab_value.procedures[rwy_id]) do 
--trigger.action.outText(mist.utils.tableShow(proc_value), 5)
										if proc_value.type == 'approach' then 
--trigger.action.outText('helllloooo', 5)
                                        	if proc_value.procedure_type  ~= 'par' and proc_value.procedure_type  ~= 'overhead' then
												local appr_data_clearance = {
													appr_type = 'clearance',
													group_value = group_value,
													proc_value = proc_value,
													ab_value = ab_value
												}
												local command = missionCommands.addCommand('Request clearance for the '..proc_value.display_name..'.',	menu,	catt.player.set_approach, 	appr_data_clearance) 
                                       		end
                                        
											local appr_data_vectors = {
														appr_type = 'vectors',
														group_value = group_value,
														proc_value = proc_value,
														ab_value = ab_value,
														vectors_approach = ab_value.vectors_approach[rwy_id],
													}
													
											local command = missionCommands.addCommand('Request vectors for the '..proc_value.display_name..'.',	menu,	catt.player.set_approach, 	appr_data_vectors) 
												
											
											
										end
									end
								end 
							end
						end
					end
				end    
            end

		elseif group_value.ato_mission.mission_state.state == 'passed_to_final_controller' then 
			missionCommands.removeItem('APPROACH')
			local appr_menu = missionCommands.addSubMenu("APPROACH"					, nil								)
			local command = missionCommands.addCommand('Abort approach.',	appr_menu,	catt.player.abort_approach, group_value) 
			local command = missionCommands.addCommand('Contact PAR Final Controller.',	appr_menu,	catt.player.passed_to_final_controller, group_value) 
			catt.player.is_appr_menu_installed = 'no'
			
		---- UNINSTALL APPROACH MENU
    	else
			missionCommands.removeItem('APPROACH')
			local appr_menu = missionCommands.addSubMenu("APPROACH"					, nil								)
			local command = missionCommands.addCommand('Abort approach.',	appr_menu,	catt.player.abort_approach, group_value) 
			catt.player.is_appr_menu_installed = 'no'
		end     
    
end





  

    
function catt.player.msg_request_appr_clearance(group_mission)
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local player_freq = 152.75 --- DA_FARE!!!!
    local iaf = group_mission.mission_state.proc_value.route[1].point
    local iaf_altitude = group_mission.mission_state.proc_value.route[1].altitude
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end

    
    local request_msg = {}
    local request_subs
    	
    	request_msg[#request_msg + 1] = appr_cs
		request_subs = '['..string.upper(capital_callsign)..'] '..appr_cs..', '..capital_callsign..', '
    	for el_id, el_val in ipairs (callsign_table) do
        	request_msg[#request_msg + 1] = el_val
        end
    		
    	request_msg[#request_msg + 1] = 'request_direct'
    	request_subs = request_subs..'request direct '
    
    	request_msg[#request_msg + 1] = iaf
    	request_subs = request_subs..iaf..' '
    
    	request_msg[#request_msg + 1] = 'for_the'
    	request_subs = request_subs..'for the '
    	
    	request_msg[#request_msg + 1] = group_mission.mission_state.proc_value.name
    	request_subs = request_subs..group_mission.mission_state.proc_value.display_name..', '
    
    	request_msg[#request_msg + 1] = 'full_stop'
    	request_subs = request_subs..'full stop.'
    

    local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	request_msg[#request_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_cs)..'] '..capital_callsign..', '..appr_cs..', '

    	clearance_msg[#clearance_msg + 1] = 'cleared_direct'
    	clearance_subs = clearance_subs..'cleared direct '
    
    	clearance_msg[#clearance_msg + 1] = iaf
    	clearance_subs = clearance_subs..iaf..', '
    
    	clearance_msg[#clearance_msg + 1] = 'descend_maintain'
    	clearance_subs = clearance_subs..'descend and maintain '
    	
    	--local altitude, altitude_table = catt.player.get_radio_altitude(iaf_altitude)
    	local altitude_for_message = catt.c2.altitude_for_message(iaf_altitude)
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		clearance_subs = clearance_subs..catt.utils.round(iaf_altitude / 1000)..',000, '
    
    	clearance_msg[#clearance_msg + 1] = 'cleared'
    	clearance_subs = clearance_subs..'cleared '
    
    	clearance_msg[#clearance_msg + 1] = group_mission.mission_state.proc_value.name
    	clearance_subs = clearance_subs..group_mission.mission_state.proc_value.display_name..'.'
		
		
		
	if appr_freq == player_freq then
        ----------- radio message
        trigger.action.outText(request_subs, 10)
		trigger.action.outText(clearance_subs, 10)
  	else
        ----------- radio message
		trigger.action.outText(request_subs, 10)
	end
    
end






   
function catt.player.msg_request_appr_vectors(group_mission) 
	local player_freq = 269.9--- DA_FARE!!!!
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
    local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end

	local request_msg = {}
    local request_subs
		request_msg[#request_msg + 1] = appr_cs
		request_subs = '['..string.upper(capital_callsign)..'] '..appr_edited_cs..', '..capital_callsign..', '
    	for el_id, el_val in ipairs (callsign_table) do
        	request_msg[#request_msg + 1] = el_val
        end
    		
    	request_msg[#request_msg + 1] = 'request_vectors'
    	request_subs = request_subs..'request vectors '
    
    	request_msg[#request_msg + 1] = 'for_the'
    	request_subs = request_subs..'for the '
    	
    	request_msg[#request_msg + 1] = group_mission.mission_state.proc_value.procedure_type..'_runway'	
	    if group_mission.mission_state.proc_value.procedure_type == 'overhead' then
	    	request_subs = request_subs..'Overhead Runway '
        else        
	    	request_subs = request_subs..string.upper(group_mission.mission_state.proc_value.procedure_type)..' Runway '
    	end
    
    
    	request_msg[#request_msg + 1] = string.sub(group_mission.mission_state.proc_value.rwy, 1, 1)
    	request_msg[#request_msg + 1] = string.sub(group_mission.mission_state.proc_value.rwy, -1)
    	request_subs = request_subs..group_mission.mission_state.proc_value.rwy
    
		if group_mission.mission_state.proc_value.procedure_type ~= 'overhead' then
			request_msg[#request_msg + 1] = 'approach'
			request_subs = request_subs..' approach, '
        else
    		request_subs = request_subs..', '
    	end
		
    	request_msg[#request_msg + 1] = 'full_stop'
    	request_subs = request_subs..'full stop.'
	
        ----------- radio message
		local request_radio_msg = {
			caller = callsign,
			msg = request_msg,
			subs = request_subs,
			freq = player_freq,
			
		}
        
		catt.radio.talker_2(request_radio_msg)
end





function catt.player.msg_turn_to_iaf(group_mission) 
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
	
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
	local player_point = player_pos.p
	
	local iaf_point
		if group_mission.mission_state.vectors_approach.iaf_2 then
			local iaf_1_point = group_mission.mission_state.vectors_approach.iaf
			local iaf_2_point = group_mission.mission_state.vectors_approach.iaf_2
			local distance_1 = catt.meas.dist2d(player_point, iaf_1_point)
			local distance_2 = catt.meas.dist2d(player_point, iaf_2_point)
			if distance_1 < distance_2 then
				iaf_point = iaf_1_point
			else
				iaf_point = iaf_2_point
			end
		else
			iaf_point = group_mission.mission_state.vectors_approach.iaf
		end
		
	local bear = catt.meas.get_bearing_with_points(player_point, iaf_point) - options.mag_var

--trigger.action.markToAll( 1 , 'iaf_point' , iaf_point)
--trigger.action.outText('bear = '..bear, 10)
--trigger.action.outText(mist.utils.tableShow(iaf_point), 5)
    
    
	local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
    
	local turn_dir = catt.meas.get_turn_dir(player_heading, bear)
    local heading_diff = math.abs(player_heading - bear)

    local target_altitude = group_mission.mission_state.vectors_approach.iaf_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt
	
	
	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if heading_diff > 5 then
			if turn_dir == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(bear, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		
    	end
    
		if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    
		
		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end    
        
		clearance_subs = clearance_subs..'.'
		
        local is_message_necessary = 'no'
    
		if heading_diff > 10 then
			is_message_necessary = 'yes'
		end
			
			
		
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  
 
end
  



function catt.player.msg_enroute_ab(group_mission) 
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
	local player_point = player_pos.p
	local ab_point = group_mission.mission_state.ab_value
	local bear = catt.meas.get_bearing_with_points(player_point, ab_point) - options.mag_var
	
	
	local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
    
	local turn_dir = catt.meas.get_turn_dir(player_heading, bear)



    local heading_diff = math.abs(player_heading - bear)
    
    local target_altitude = group_mission.mission_state.vectors_approach.downwind_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt

	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if heading_diff > 5 then
			if turn_dir == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(bear, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		end
    
		if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    
		
		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end    
        
		clearance_subs = clearance_subs..'.'
    
    local is_message_necessary = 'no'
    
    if heading_diff > 10 then
        is_message_necessary = 'yes'
  	end
        
		
	
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  

    
end




function catt.player.msg_turn_to_downwind(group_mission) 
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading
   	local rwy_opp = catt.utils.round_angle(rwy_heading - 180)
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
    local player_point = player_pos.p
    local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
    local turn_dir = catt.meas.get_turn_dir(player_heading, rwy_opp)
    local target_altitude = group_mission.mission_state.vectors_approach.base_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt
	local heading_diff = math.abs(player_heading - rwy_opp)

	local clearance_msg = {}
    local clearance_subs

    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

		if heading_diff > 5 then
			if turn_dir == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(rwy_opp, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		end
		
		if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    

		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end    
        
		clearance_subs = clearance_subs..'.'

    local is_message_necessary = 'no'
    
    if heading_diff > 10 then
        is_message_necessary = 'yes'
  	end

	
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  

end



function catt.player.msg_enroute_to_downwind(group_mission, turn_dir) 
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
	local player_point = player_pos.p
	local ab_point = group_mission.mission_state.ab_value
	local bear = catt.meas.get_bearing_with_points(ab_point, player_point) - options.mag_var
	local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
    
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading
    local rwy_opp = catt.utils.round_angle(rwy_heading - 180)
	local rwy_dir = catt.meas.get_turn_dir(rwy_heading, bear)
    
    local turn_heading
    if turn_dir == 'turn_in' then
        if rwy_dir == 'left' then

	        turn_heading = catt.utils.round_angle(rwy_opp - 45)
      	else
        	turn_heading = catt.utils.round_angle(rwy_opp + 45)
        end      
    elseif turn_dir == 'turn_out' then
        if rwy_dir == 'left' then
	        turn_heading = catt.utils.round_angle(rwy_opp + 45)
      	else
        	turn_heading = catt.utils.round_angle(rwy_opp - 45)
        end 
    elseif turn_dir == 'ok' then
	        turn_heading = rwy_opp
	end
	
	local turn_side = catt.meas.get_turn_dir(player_heading, turn_heading)

--trigger.action.outText('rwy_dir = '..rwy_dir, 10)    

    local heading_diff = math.abs(player_heading - turn_heading)
    
    local target_altitude = group_mission.mission_state.vectors_approach.base_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt

	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if heading_diff > 10 then
			if turn_side == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(turn_heading, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		end
    
		if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    
		
		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end    
        
		clearance_subs = clearance_subs..'.'
    
    local is_message_necessary = 'no'
    
    if alt_diff > 300 or alt_diff < -300 then
        is_message_necessary = 'yes'
    end
    if heading_diff > 15 then
        is_message_necessary = 'yes'
  	end
        
		
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  
    
end





function catt.player.msg_turn_to_base(group_mission) 
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
	local player_point = player_pos.p
	local treshold_point = group_mission.mission_state.vectors_approach.threshold
	local bear = catt.meas.get_bearing_with_points(player_point, treshold_point) - options.mag_var
	local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
	local treshold_dir = catt.meas.get_turn_dir(player_heading, bear)
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading

    local turn_heading
    if treshold_dir == 'left' then
        turn_heading = catt.utils.round_angle(rwy_heading + 90)
    else
        turn_heading = catt.utils.round_angle(rwy_heading - 90)
	end
    
    local heading_diff = math.abs(player_heading - turn_heading)
    
    local target_altitude = group_mission.mission_state.vectors_approach.final_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt

	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if heading_diff > 10 then
			if treshold_dir == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(turn_heading, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		end
    
		if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    
		
		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end    
        
		clearance_subs = clearance_subs..'.'
    
    local is_message_necessary = 'no'
    
    if alt_diff > 300 or alt_diff < -300 then
        is_message_necessary = 'yes'
    end
    if heading_diff > 10 then
        is_message_necessary = 'yes'
  	end
        
		
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  
    
end


function catt.player.msg_turn_to_intercept_fac(group_mission) 
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end
	
    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
	local player_point = player_pos.p
	local treshold_point = group_mission.mission_state.vectors_approach.threshold
	local bear = catt.meas.get_bearing_with_points(player_point, treshold_point) - options.mag_var
	local player_heading = catt.meas.get_heading(player_pos) - options.mag_var
	local treshold_dir = catt.meas.get_turn_dir(player_heading, bear)
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading

    local turn_heading
    if treshold_dir == 'left' then
        turn_heading = catt.utils.round_angle(rwy_heading + 30)
    else
        turn_heading = catt.utils.round_angle(rwy_heading - 30)
	end
    
    local heading_diff = math.abs(player_heading - turn_heading)
     
    local target_altitude = group_mission.mission_state.vectors_approach.final_alt
    local player_alt = catt.meas.get_altitude_point(player_point)
    local alt_diff = target_altitude - player_alt


	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if heading_diff > 10 then
			if treshold_dir == 'left' then
				clearance_msg[#clearance_msg + 1] = 'turn_left'
				clearance_subs = clearance_subs..'turn left '
			else
				clearance_msg[#clearance_msg + 1] = 'turn_right'
				clearance_subs = clearance_subs..'turn right '
			end
		
			clearance_msg[#clearance_msg + 1] = 'heading'
			clearance_subs = clearance_subs..'heading '
			
			local degrees_for_message = catt.c2.degrees_for_message(turn_heading, 'no')
		
			clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
			clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
			clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..', '
		end
    
		 if alt_diff < 300 and alt_diff > -300 then
			clearance_msg[#clearance_msg + 1] = 'maintain'
			clearance_subs = clearance_subs..'maintain '
		elseif alt_diff > 300 then
			clearance_msg[#clearance_msg + 1] = 'climb_maintain'
			clearance_subs = clearance_subs..'climb and maintain '
		elseif alt_diff < -300 then
			clearance_msg[#clearance_msg + 1] = 'descend_maintain'
			clearance_subs = clearance_subs..'descend and maintain '
		end    
		
		local altitude_for_message = catt.c2.altitude_for_message(target_altitude, 'no')
		local thousands = math.floor(target_altitude / 1000)
		local hundreds = catt.utils.round(((target_altitude / 1000) - thousands)* 10) 
			for alt_name, alt_value in ipairs (altitude_for_message) do
				clearance_msg[#clearance_msg + 1] = alt_value
			end
		if target_altitude > 1000 then
			clearance_subs = clearance_subs..thousands..','..hundreds..'00'
		else
			clearance_subs = clearance_subs..hundreds..'00'
		end   
        
		clearance_subs = clearance_subs..'.'
    
    local is_message_necessary = 'no'
    
   
   if alt_diff > 300 or alt_diff < -300 then
        is_message_necessary = 'yes'
    end
    if heading_diff > 10 then
        is_message_necessary = 'yes'
  	end
         
		
	if is_message_necessary == 'yes' then
		local radio_msg = {
			caller = appr_cs,
			msg = clearance_msg,
			subs = clearance_subs,
			freq = appr_freq,
			
		}
			
		catt.radio.talker_2(radio_msg)
	end  
    
end




function catt.player.msg_turn_to_fac(group_mission) 
	local appr_freq = group_mission.mission_state.ab_value.appr_freq
    local appr_cs = group_mission.mission_state.ab_value.appr_cs
	local appr_edited_cs = catt.utils.elaborate_string(appr_cs, 'all_capital')
    local callsign = group_mission.group_name
    local capital_callsign , callsign_table = catt.player.get_radio_callsign(callsign)
    if callsign_table[2] then
        capital_callsign = capital_callsign..' '..callsign_table[2]
	end
    if callsign_table[3] then
        capital_callsign = capital_callsign..'-'..callsign_table[3]
	end

    local player_pos = Group.getByName(group_mission.group_name):getUnits()[1]:getPosition()
    local player_heading = catt.meas.get_heading(player_pos)
    local rwy_heading = group_mission.mission_state.vectors_approach.rwy_heading
    local tur_dir = catt.meas.get_turn_dir(player_heading, rwy_heading)
    
    local procedure_type = group_mission.mission_state.proc_value.procedure_type

	local clearance_msg = {}
    local clearance_subs
    
    	for el_id, el_val in ipairs (callsign_table) do
        	clearance_msg[#clearance_msg + 1] = el_val
        end
    	clearance_msg[#clearance_msg + 1] = appr_cs
		clearance_subs = '['..string.upper(appr_edited_cs)..'] '..capital_callsign..', '..appr_edited_cs..', '

    	if tur_dir == 'left' then
			clearance_msg[#clearance_msg + 1] = 'turn_left'
			clearance_subs = clearance_subs..'turn left '
		else
			clearance_msg[#clearance_msg + 1] = 'turn_right'
			clearance_subs = clearance_subs..'turn right '
		end
		
    	clearance_msg[#clearance_msg + 1] = 'heading'
    	clearance_subs = clearance_subs..'heading '
    
    	local degrees_for_message = catt.c2.degrees_for_message(rwy_heading, 'no')
    
    	clearance_msg[#clearance_msg + 1] = degrees_for_message[1]
    	clearance_msg[#clearance_msg + 1] = degrees_for_message[2]
    	clearance_msg[#clearance_msg + 1] = degrees_for_message[3]
    	clearance_subs = clearance_subs..degrees_for_message[1]..degrees_for_message[2]..degrees_for_message[3]..' '
    
    	clearance_msg[#clearance_msg + 1] = 'for_final_approach'
    	clearance_subs = clearance_subs..'for final approach. '
    
    if procedure_type ~= 'par' then
    	clearance_msg[#clearance_msg + 1] = 'contact_tower_on'
    	clearance_subs = clearance_subs..'Contact Tower on '
		local tower_freq = group_mission.mission_state.ab_value.tower_freq
		local tower_digits = catt.c2.digits_for_message(tower_freq)
    	for id, value in ipairs (tower_digits) do
        	clearance_msg[#clearance_msg + 1] = value
        	if value == 'point' then
            	clearance_subs = clearance_subs..'.'
            else
            	clearance_subs = clearance_subs..value
            end
        end
    else
		clearance_msg[#clearance_msg + 1] = 'contact_final_controller_on'
    	clearance_subs = clearance_subs..'Contact Final Controller on '
		local final_controller_freq = group_mission.mission_state.ab_value.final_controller_freq
		local final_controller_digits = catt.c2.digits_for_message(final_controller_freq)
    	for id, value in ipairs (final_controller_digits) do
        	clearance_msg[#clearance_msg + 1] = value
        	if value == 'point' then
            	clearance_subs = clearance_subs..'.'
            else
            	clearance_subs = clearance_subs..value
            end
        end
	end
	
		
	local radio_msg = {
		caller = appr_cs,
		msg = clearance_msg,
		subs = clearance_subs,
		freq = appr_freq,
			
	}
			
	catt.radio.talker_2(radio_msg)
	  
    
end












    






