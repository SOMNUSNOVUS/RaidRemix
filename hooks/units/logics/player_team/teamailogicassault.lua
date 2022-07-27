function TeamAILogicAssault.update(data)
	TeamAILogicTravel._upd_ai_perceptors(data)

	local my_data = data.internal_data
	local t = data.t
	local unit = data.unit
	local focus_enemy = data.attention_obj
	local in_cover = my_data.in_cover
	local best_cover = my_data.best_cover

	CopLogicAttack._process_pathing_results(data, my_data)

	local focus_enemy = data.attention_obj

	if not focus_enemy or focus_enemy.reaction < AIAttentionObject.REACT_AIM then
		TeamAILogicAssault._upd_enemy_detection(data, true)

		if my_data ~= data.internal_data or not data.attention_obj or data.attention_obj.reaction <= AIAttentionObject.REACT_SCARED then
			return
		end

		focus_enemy = data.attention_obj
	end

	if not data.objective or data.objective.type == "free" then
		if not data.path_fail_t or data.t - data.path_fail_t > 2 then
			managers.groupai:state():on_criminal_jobless(data.unit)

			if my_data ~= data.internal_data then
				return
			end
		end
	end
	
	if my_data.cover_chk_t < data.t then
		CopLogicAttack._update_cover(data)

		my_data.cover_chk_t = data.t + TeamAILogicAssault._COVER_CHK_INTERVAL
	end
	
	local enemy_visible = focus_enemy.verified
	local action_taken = my_data.turning or data.unit:movement():chk_action_forbidden("walk") or my_data.moving_to_cover or my_data.walking_to_cover_shoot_pos or my_data._turning_to_intimidate
	my_data.want_to_take_cover = CopLogicAttack._chk_wants_to_take_cover(data, my_data)
	local want_to_take_cover = my_data.want_to_take_cover
	action_taken = action_taken or CopLogicAttack._upd_pose(data, my_data)
	local move_to_cover = nil

	if action_taken then
		-- Nothing
	elseif want_to_take_cover then
		move_to_cover = true
	end

	if not my_data.processing_cover_path and not my_data.cover_path and not my_data.charge_path_search_id and not action_taken and best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) then
		CopLogicAttack._cancel_cover_pathing(data, my_data)

		local search_id = tostring(unit:key()) .. "cover"

		if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[NavigationManager.COVER_RESERVATION]) then
			my_data.cover_path_search_id = search_id
			my_data.processing_cover_path = best_cover
		end
	end

	if not action_taken and move_to_cover and my_data.cover_path then
		action_taken = CopLogicAttack._request_action_walk_to_cover(data, my_data)
	end
end

function TeamAILogicAssault._find_cover_for_follow(data, my_data, threat_pos)
	local near_pos = data.objective.follow_unit:movement():m_pos()

	if my_data.best_cover and CopLogicAttack._verify_follow_cover(my_data.best_cover[1], near_pos, threat_pos, 200, 1000) or my_data.processing_cover_path or my_data.charge_path_search_id then
		return
	end

	local follow_unit_area = managers.groupai:state():get_area_from_nav_seg_id(data.objective.follow_unit:movement():nav_tracker():nav_segment())
	local campers = TeamAILogicTravel._players_that_are_camping()
	local cones_to_send = TeamAILogicTravel._unit_cones(campers, 400)
	local cover = managers.navigation:find_cover_in_nav_seg_excluding_cones(follow_unit_area.nav_segs, 450, near_pos, threat_pos, cones_to_send)

	if not found_cover then
		return
	end

	if not follow_unit_area.nav_segs[found_cover[NavigationManager.COVER_TRACKER]:nav_segment()] then
		debug_pause_unit(data.unit, "cover in wrong area")
	end

	local better_cover = {
		found_cover
	}

	CopLogicAttack._set_best_cover(data, my_data, better_cover)

	local offset_pos = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)

	if offset_pos then
		offset_pos = managers.navigation:pad_out_position(offset_pos, 4, data.char_tweak.wall_fwd_offset)
		better_cover[NavigationManager.COVER_RESERVATION] = offset_pos
	end
end