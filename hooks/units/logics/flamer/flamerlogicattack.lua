local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_sub = mvector3.subtract
local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_lerp = mvector3.lerp
local mvec3_norm = mvector3.normalize
local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()

function FlamerLogicAttack.update(data)
	local t = data.t
	local unit = data.unit
	local my_data = data.internal_data

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
		
		if my_data.has_old_action then
			return
		end
	end

	if CopLogicBase._chk_relocate(data) then
		return
	end

	if not data.attention_obj or data.attention_obj.reaction < AIAttentionObject.REACT_AIM then
		CopLogicAttack._upd_enemy_detection(data, true)

		if my_data ~= data.internal_data or not data.attention_obj or data.attention_obj.reaction < AIAttentionObject.REACT_AIM then
			return
		end
	end

	local focus_enemy = data.attention_obj

	FlamerLogicAttack._process_pathing_results(data, my_data)

	local enemy_visible = focus_enemy.verified
	local engage = my_data.attitude == "engage"
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.walking_to_chase_pos

	if action_taken then
		return
	end

	if unit:anim_data().crouch then
		action_taken = CopLogicAttack._request_action_stand(data)
	end

	if action_taken then
		return
	end

	local enemy_pos = enemy_visible and focus_enemy.m_pos or focus_enemy.verified_pos
	action_taken = CopLogicAttack._request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)

	if action_taken then
		return
	end

	local chase = nil
	local z_dist = math.abs(data.m_pos.z - focus_enemy.m_pos.z)

	if AIAttentionObject.REACT_COMBAT <= focus_enemy.reaction then
		if enemy_visible then
			if z_dist < 300 or focus_enemy.verified_dis > 2000 or engage and focus_enemy.verified_dis > 500 then
				chase = true
			end

			if focus_enemy.verified_dis < 800 and unit:anim_data().run then
				local new_action = {
					body_part = 2,
					type = "idle"
				}

				data.unit:brain():action_request(new_action)
			end
		elseif z_dist < 300 or focus_enemy.verified_dis > 2000 or engage and (not focus_enemy.verified_t or t - focus_enemy.verified_t > 5 or focus_enemy.verified_dis > 700) then
			chase = true
		end
	end

	if chase then
		if my_data.walking_to_chase_pos then
			-- Nothing
		elseif my_data.pathing_to_chase_pos then
			-- Nothing
		elseif my_data.chase_path then
			local dist = focus_enemy.verified_dis
			local run_dist = focus_enemy.verified and 1500 or 800
			local walk = dist < run_dist

			FlamerLogicAttack._chk_request_action_walk_to_chase_pos(data, my_data, walk and "walk" or "run")
		elseif focus_enemy.nav_tracker then
			my_data.chase_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.nav_tracker, 900)

			if my_data.chase_pos then
				my_data.chase_pos = managers.navigation:pad_out_position(my_data.chase_pos, 4, 93)
				
				my_data.chase_path_search_id = tostring(unit:key()) .. "chase"
				my_data.pathing_to_chase_pos = true
				local to_pos = my_data.chase_pos
				my_data.chase_pos = nil

				data.brain:add_pos_rsrv("path", {
					radius = 60,
					position = mvector3.copy(to_pos)
				})
				unit:brain():search_for_path(my_data.chase_path_search_id, to_pos)
			end
		end
	else
		FlamerLogicAttack._cancel_chase_attempt(data, my_data)
	end
end

function FlamerLogicAttack.queue_update(data, my_data)
	my_data.update_queued = true

	CopLogicBase.queue_task(my_data, my_data.update_queue_id, FlamerLogicAttack.queued_update, data, data.t + 0.2, data.important)
end

function FlamerLogicAttack._pathing_complete_clbk(data)
	local my_data = data.internal_data

	if my_data.pathing_to_chase_pos then
		FlamerLogicAttack._process_pathing_results(data, my_data)
		
		if my_data.chase_path then
			local focus_enemy = data.attention_obj
			
			if not focus_enemy then
				return
			end
			
			local dist = focus_enemy.verified_dis or focus_enemy.dis
			local run_dist = focus_enemy.verified and 1500 or 800
			local walk = dist < run_dist

			FlamerLogicAttack._chk_request_action_walk_to_chase_pos(data, my_data, walk and "walk" or "run")
		end
	end
end