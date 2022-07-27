local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local mrot1 = Rotation()

function CopLogicBase.is_obstructed(data, objective, strictness, attention)
	local my_data = data.internal_data
	attention = attention or data.attention_obj

	if not objective or objective.is_default or (objective.in_place or not objective.nav_seg) and not objective.action then
		return true, false
	end

	if objective.interrupt_suppression and data.is_suppressed then
		return true, true
	end

	strictness = strictness or 0

	if objective.interrupt_health then
		local health_ratio = data.unit:character_damage():health_ratio()

		if health_ratio < 1 and health_ratio * (1 - strictness) < objective.interrupt_health then
			return true, true
		end
	end
	
	--https://cdn.discordapp.com/attachments/958251616597843969/980863861177602129/losing_it.mp4
	
	if not data.cool and data.unit:base()._tweak_table == "german_flamer" and attention and AIAttentionObject.REACT_COMBAT <= attention.reaction and (objective.type == "defend_area" or objective.type == "assault_area") then
		if attention.verified or attention.verified_t and data.t - attention.verified_t < 15 then
			local engage_range = 1800

			if attention.dis < engage_range then
				return true, true
			end
		end
	end
	
	if objective.interrupt_on_contact then
		if attention and AIAttentionObject.REACT_COMBAT <= attention.reaction then
			if attention.verified or attention.verified_t and data.t - attention.verified_t < 15 then
				local weapon = data.unit:inventory():equipped_unit()
				local usage = weapon and weapon:base():weapon_tweak_data().usage
				local range_entry = usage and (data.char_tweak.weapon[usage] or {}).range or {}
				local engage_range = range_entry.optimal or 2000

				if attention.dis < engage_range then
					return true, true
				end
			end
		end
	end

	if objective.interrupt_dis then
		if attention and (AIAttentionObject.REACT_COMBAT <= attention.reaction or data.cool and AIAttentionObject.REACT_SURPRISED <= attention.reaction) then
			if objective.interrupt_dis == -1 then
				return true, true
			elseif math.abs(attention.m_pos.z - data.m_pos.z) < 250 then
				local enemy_dis = attention.dis * (1 - strictness)

				if not attention.verified then
					enemy_dis = 2 * attention.dis * (1 - strictness)
				end

				if attention.is_very_dangerous then
					enemy_dis = enemy_dis * 0.25
				end

				if enemy_dis < objective.interrupt_dis then
					return true, true
				end
			end

			if objective.pos and math.abs(attention.m_pos.z - objective.pos.z) < 250 then
				local enemy_dis = mvector3.distance(objective.pos, attention.m_pos) * (1 - strictness)

				if enemy_dis < objective.interrupt_dis then
					return true, true
				end
			end
		elseif objective.interrupt_dis == -1 and not data.unit:movement():cool() then
			return true, true
		end
	end

	return false, false
end

function CopLogicBase._chk_relocate(data)
	if data.objective and data.objective.type == "follow" then
		if data.is_converted then
			if TeamAILogicIdle._check_should_relocate(data, data.internal_data, data.objective) then
				data.objective.in_place = nil

				data.logic._exit(data.unit, "travel")

				return true
			end

			return
		end

		if data.is_tied and data.objective.lose_track_dis and data.objective.lose_track_dis * data.objective.lose_track_dis < mvector3.distance_sq(data.m_pos, data.objective.follow_unit:movement():m_pos()) then
			data.brain:set_objective(nil)

			return true
		end

		local relocate = nil
		local follow_unit = data.objective.follow_unit
		local advance_pos = follow_unit:brain() and follow_unit:brain():is_advancing()
		local follow_unit_pos = advance_pos or follow_unit:movement():m_pos()

		if data.objective.relocated_to and mvector3.equal(data.objective.relocated_to, follow_unit_pos) then
			return false
		end

		if data.objective.distance and data.objective.distance < mvector3.distance(data.m_pos, follow_unit_pos) then
			relocate = true
		end

		if not relocate then
			local ray_params = {
				tracker_from = data.unit:movement():nav_tracker(),
				pos_to = follow_unit_pos
			}
			local ray_res = managers.navigation:raycast(ray_params)

			if ray_res then
				relocate = true
			end
		end

		if relocate then
			data.objective.in_place = nil
			data.objective.nav_seg = follow_unit:movement():nav_tracker():nav_segment()
			data.objective.relocated_to = mvector3.copy(follow_unit_pos)

			data.logic._exit(data.unit, "travel")

			return true
		end
	end
	
	return false
end

function CopLogicBase:_optimize_path(path, data)		
	if #path <= 2 then
		return path
	end

	local opt_path = {}
	local nav_path = {}
	
	for i = 1, #path do
		local nav_point = path[i]

		if nav_point.x then
			nav_path[#nav_path + 1] = nav_point
		elseif alive(nav_point) then
			nav_path[#nav_path + 1] = {
				element = nav_point:script_data().element,
				c_class = nav_point
			}
		else
			return path
		end
	end
	
	nav_path = CopActionWalk._calculate_simplified_path(path[1], nav_path, 3, true, true)
	
	for i = 1, #nav_path do
		local nav_point = nav_path[i]
		
		if nav_point.c_class then
			opt_path[#opt_path + 1] = nav_point.c_class
		else
			opt_path[#opt_path + 1] = nav_point
		end
	end

	return opt_path
end