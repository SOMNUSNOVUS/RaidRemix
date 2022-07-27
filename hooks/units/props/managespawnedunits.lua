local flamer_objects = {
	Idstring("g_flamer_armor_upper"),
	Idstring("g_flamer_armor_shoulder_l"),
	Idstring("g_flamer_armor_lower"),
	Idstring("g_flamer_armor_shoulder_r")
}

local function dmg_func_empty(...)
	return
end

function ManageSpawnedUnits:run_flamer_staticize()
	for key, entry in pairs(self._spawned_units) do
		if alive(entry.unit) then
			if key ~= "tank_collision" and entry.unit:body("body_static"):enabled() then
				entry.unit:set_slot(17)
				
				entry.unit:body("body_static"):extension().damage.damage_explosion = dmg_func_empty
				entry.unit:body("body_static"):extension().damage.damage_damage = dmg_func_empty
				entry.unit:body("body_static"):extension().damage.damage_fire = dmg_func_empty
				
				entry.unit:body("body_static"):set_keyframed()

				if entry.unit:get_object(Idstring("g_g")) then
					entry.unit:get_object(Idstring("g_g")):set_visibility(true)
				else
					for i = 1, #flamer_objects do
						local object = flamer_objects[i]
							
						if entry.unit:get_object(object) then
							entry.unit:get_object(object):set_visibility(true)
						end
					end
				end
			else
				entry.unit:set_slot(17)
			
				entry.unit:body("body_static"):extension().damage.damage_explosion = dmg_func_empty
				entry.unit:body("body_static"):extension().damage.damage_damage = dmg_func_empty
				entry.unit:body("body_static"):extension().damage.damage_fire = dmg_func_empty
				
				entry.unit:body("body_static"):set_keyframed()
			end
		end
	end
end

function ManageSpawnedUnits:sync_unit_spawn(unit_id)
	if self._sync_spawn_and_link and self._sync_spawn_and_link[unit_id] then
		self:_link_joints(unit_id, self._sync_spawn_and_link[unit_id].joint_table)

		self._sync_spawn_and_link[unit_id] = nil
	else
		self._temp_link_units = self._temp_link_units or {}
		self._temp_link_units[unit_id] = true
	end
	
	if Network:is_client() then
		if self._unit:base()._tweak_table == "german_flamer" then 
			self:run_flamer_staticize()
		end
	end
end
