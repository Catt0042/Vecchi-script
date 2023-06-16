catt = {}


-- utility

catt.utils = {}

function catt.utils.get_true_speed(object)
    local unitvel = object:getVelocity()
    local unitspeed = (unitvel.x^2 + unitvel.y^2 + unitvel.z^2)^0.5
    local unitspeed = unitspeed * 1.94384
    return unitspeed
end

function catt.utils.get_heigh_feet_msl(object)
    local unitposition = object:getPoint()
    local altitude = unitposition.y
    local altitude = altitude * 3.28084
    return altitude
end    

function catt.utils.get_ias(object)
	local tas = catt.utils.get_true_speed(object)
	local altitude = catt.utils.get_heigh_feet_msl(object)
	local ias = catt.conv.tas_to_ias(tas, altitude)
	return ias 
end

-- conversions

catt.conv = {}

function catt.conv.tas_to_ias(tas, altitude)
	local ias = tas*(1-6.8755856*10^-6*(altitude))^2.12794
	return ias
end


-- MAR Calculator

--ISTRUZIONI
--Posizona l'attacker a ore 6 del defender con shoot at max range nell'init
--Posizona il defender a grande distanza togliendo la reazione alla minaccia e con immortalità e max speed
--crea missioni di test a 5,000 - 10,000 - 15,000 - 20,000 - 30,000 e 40,000 feet
--richiede MIST


catt.tailWEZCalc = {}
catt.tailWEZCalc.testTable = {}

catt.tailWEZCalc.minMissileIAS = 400 -- inserire valore
catt.tailWEZCalc.minMissileTAS = 600 -- inserire valore

function catt.tailWEZCalc.Calculator ()
    missile_tester_handler = {}
        function missile_tester_handler:onEvent(event)
            if event.id == world.event.S_EVENT_SHOT then 
--trigger.action.outText ( "text", 100 ) 
            local aircraft = event.initiator
		local missile_table = {}
                missile_table.weapon = event.weapon
                missile_table.weapon_name = event.weapon:getDesc().displayName
                missile_table.initial_point = event.initiator:getPoint()
                missile_table.initial_time = timer.getTime()
--trigger.action.markToAll(1, 'start point', event.initiator:getPoint())
		table.insert(catt.tailWEZCalc.testTable, missile_table)
		--trigger.action.outText(('Missile name = '..missile_table.weapon_name..'\n time = '..missile_table.initial_time), 200, true)
		timer.scheduleFunction(catt.tailWEZCalc.missile_checker, nil, timer.getTime() + 5) 
-- il ritardo permette al missile di accellerare e superare la velocità che termina la funzione
            --timer.scheduleFunction(destroy_target, nil, timer.getTime() + time_to_destroy_target)            
            end    
        end
world.addEventHandler(missile_tester_handler)
end
--catt.tailWEZCalc.Calculator ()


function catt.tailWEZCalc.missile_checker()
   for ind, value in pairs (catt.tailWEZCalc.testTable) do
        if value.weapon_name then
            if value.weapon:getVelocity() then
                local unit_ias = catt.utils.get_ias(value.weapon)
				local unit_tas = catt.utils.get_true_speed(value.weapon)
                --value.speed = unit_speed
--                if unit_ias < catt.tailWEZCalc.minMissileIAS or unit_tas < catt.tailWEZCalc.minMissileTAS then
--                    local last_point = value.weapon:getPoint()
----trigger.action.markToAll(2, 'end point', last_point)
----trigger.action.outText(mist.utils.tableShow(last_point), 20)      
--                    local distance = mist.utils.get2DDist(last_point ,value.initial_point)/1852
--                    local timer = timer.getTime() - value.initial_time
--trigger.action.outText(('RESULTS\n\n Missile name = '..value.weapon_name..'\n Distance covered = '..distance..'\n time elapsed = '..timer), 200, true)
--                    return nil
--                   else
--trigger.action.outText((unit_speed), 0.1)
--                
--                end
            end
        end
     end 
return timer.getTime() + 0.3        
end

--ACTUATOR
--catt.tailWEZCalc.Calculator ()
--ACTUATOR


--------------------------- CATT IADS ---------------------

catt.IADS = {}



