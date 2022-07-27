local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
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

function CopLogicAttack.enter(data, new_logic_name, enter_params)
	local my_data = {
		unit = data.unit
	}

	CopLogicBase.enter(data, new_logic_name, enter_params, my_data)
	data.unit:brain():cancel_all_pathing_searches()

	local old_internal_data = data.internal_data
	data.internal_data = my_data
	my_data.detection = data.char_tweak.detection.combat
	my_data.vision = data.char_tweak.vision.combat
	local weapon_usage = data.unit:inventory():equipped_unit():base():weapon_tweak_data().usage
	my_data.weapon_range = data.char_tweak.weapon[weapon_usage].range
	my_data.weapon_range_max = data.char_tweak.weapon[weapon_usage].max_range
	my_data.additional_weapon_stats = data.char_tweak.weapon[weapon_usage].additional_weapon_stats

	if old_internal_data then
		my_data.turning = old_internal_data.turning
		my_data.firing = old_internal_data.firing
		my_data.shooting = old_internal_data.shooting
		my_data.attention_unit = old_internal_data.attention_unit
	end

	my_data.peek_to_shoot_allowed = true
	my_data.detection_task_key = "CopLogicAttack._upd_enemy_detection" .. tostring(data.key)

	CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicAttack._upd_enemy_detection, data, data.t)
	CopLogicBase._chk_has_old_action(data, my_data)

	my_data.attitude = data.objective and data.objective.attitude or "engage"

	data.unit:brain():set_update_enabled_state(false)

	if data.cool then
		data.unit:movement():set_cool(false)
	end

	if (not data.objective or not data.objective.stance) and data.unit:movement():stance_code() == 1 then
		data.unit:movement():set_stance("hos")
	end

	if my_data ~= data.internal_data then
		return
	end

	my_data.update_queue_id = "CopLogicAttack.queued_update" .. tostring(data.key)

	if data.objective and (data.objective.action_duration or data.objective.action_timeout_t and data.t < data.objective.action_timeout_t) then
		CopLogicBase.request_action_timeout_callback(data)
	end

	data.unit:brain():set_attention_settings({
		cbt = true
	})
	
	CopLogicAttack.queued_update(data)
end

function CopLogicAttack.queued_update(data)
	local my_data = data.internal_data
	data.t = TimerManager:game():time()

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
		
		if my_data.has_old_action then
			CopLogicAttack.queue_update(data, my_data)

			return
		end
	end

	if CopLogicBase._chk_relocate(data) then
		return
	end

	CopLogicAttack._process_pathing_results(data, my_data)

	if not data.attention_obj or data.attention_obj.reaction < AIAttentionObject.REACT_AIM then
		CopLogicAttack._upd_enemy_detection(data, true)

		if my_data ~= data.internal_data or not data.attention_obj then
			return
		end
	end
	
	if data.team.id == "criminal1" and (not data.objective or data.objective.type == "free") and (not data.path_fail_t or data.t - data.path_fail_t > 2) then
		managers.groupai:state():on_criminal_jobless(data.unit)

		if my_data ~= data.internal_data then
			return
		end
	end

	if AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
		my_data.want_to_take_cover = CopLogicAttack._chk_wants_to_take_cover(data, my_data)

		CopLogicAttack._update_cover(data)
		CopLogicAttack._upd_combat_movement(data)
		
		--uncomment to draw coplogicattack movement behaviors
		--white = cover_shoot_pos or retreat
		--flank cover: yellow, red when moving_to_cover
		--not flank cover: green, blue when moving_to_cover
		
		--CopLogicAttack._draw_debug_movement(data, my_data)

	end

	CopLogicAttack.queue_update(data, my_data)
end

function CopLogicAttack._draw_debug_movement(data, my_data)
	if my_data.flank_cover then
		if my_data.flank_cover.failed then
			local linef = Draw:brush(Color.blue:with_alpha(0.5), 0.2)
			linef:sphere(data.m_pos, 30)
		end
		
		if my_data.walking_to_cover_shoot_pos or my_data.retreating then
			local walk_to_pos = data.unit:movement():get_walk_to_pos()
			local line = Draw:brush(Color.white:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, walk_to_pos, 5)
			line:cylinder(walk_to_pos, walk_to_pos + math.UP * 41, 5)
		elseif my_data.moving_to_cover then
			local height = 41
			local line = Draw:brush(Color.red:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, my_data.moving_to_cover[1][1], 5)
			line:cylinder(my_data.moving_to_cover[1][1], my_data.moving_to_cover[1][1] + math.UP * height, 5)
			
			if my_data.moving_to_cover[5] then
				line:cylinder(my_data.moving_to_cover[1][1], my_data.moving_to_cover[5], 5)
			end
		elseif my_data.in_cover then
			local height = my_data.in_cover[4] and 165 or 82.5
			local line = Draw:brush(Color.yellow:with_alpha(0.5), 0.2)
			
			if my_data.in_cover[5] then
				line:cylinder(my_data.in_cover[5], my_data.in_cover[5] + math.UP * height, 100)
			else
				line:cylinder(my_data.in_cover[1][1], my_data.in_cover[1][1] + math.UP * height, 100)
			end
		elseif my_data.best_cover then
			local height = 41
			local line = Draw:brush(Color.yellow:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, my_data.best_cover[1][1], 5)
			line:cylinder(my_data.best_cover[1][1], my_data.best_cover[1][1] + math.UP * height, 5)
			
			if my_data.best_cover[5] then
				line:cylinder(my_data.best_cover[1][1], my_data.best_cover[5], 5)
			end
		end
	else
		if my_data.walking_to_cover_shoot_pos or my_data.retreating then
			local walk_to_pos = data.unit:movement():get_walk_to_pos()
			local line = Draw:brush(Color.white:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, walk_to_pos, 5)
			line:cylinder(walk_to_pos, walk_to_pos + math.UP * 41, 5)
		elseif my_data.moving_to_cover then
			local height = 41
			local line = Draw:brush(Color.blue:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, my_data.moving_to_cover[1][1], 5)
			line:cylinder(my_data.moving_to_cover[1][1], my_data.moving_to_cover[1][1] + math.UP * height, 5)
			
			if my_data.moving_to_cover[5] then
				line:cylinder(my_data.moving_to_cover[1][1], my_data.moving_to_cover[5], 5)
			end
		elseif my_data.in_cover then
			local height = my_data.in_cover[4] and 165 or 82.5
			local line = Draw:brush(Color.green:with_alpha(0.5), 0.2)
			
			if my_data.in_cover[5] then
				line:cylinder(my_data.in_cover[5], my_data.in_cover[5] + math.UP * height, 100)
			else
				line:cylinder(my_data.in_cover[1][1], my_data.in_cover[1][1] + math.UP * height, 100)
			end
		elseif my_data.best_cover then
			local height = 41
			local line = Draw:brush(Color.green:with_alpha(0.5), 0.2)
			line:cylinder(data.m_pos, my_data.best_cover[1][1], 5)
			line:cylinder(my_data.best_cover[1][1], my_data.best_cover[1][1] + math.UP * height, 5)
			
			if my_data.best_cover[5] then
				line:cylinder(my_data.best_cover[1][1], my_data.best_cover[5], 5)
			end
		end
	end
end

function CopLogicAttack.queue_update(data, my_data, delay)
	local update_delay = delay
	update_delay = update_delay or data.important and 0.2 or 0.7

	CopLogicBase.queue_task(my_data, my_data.update_queue_id, data.logic.queued_update, data, data.t + update_delay, true)
end

function CopLogicAttack._pathing_complete_clbk(data)
	local my_data = data.internal_data

	if my_data.processing_cover_path or my_data.charge_path_search_id then
		data.logic._process_pathing_results(data, my_data)
		
		if my_data.cover_path or my_data.charge_path then
			CopLogicAttack._upd_combat_movement(data)
		end
	end
end

function CopLogicAttack._start_action_move_back(data, my_data, focus_enemy, engage)
	local from_pos = mvector3.copy(data.m_pos)
	local threat_tracker = focus_enemy.nav_tracker
	local threat_head_pos = focus_enemy.m_head_pos
	local max_walk_dis = 400
	local vis_required = engage
	local retreat_to = CopLogicAttack._find_retreat_position(from_pos, focus_enemy.m_pos, threat_head_pos, threat_tracker, max_walk_dis, vis_required)
	
	if retreat_to then
		retreat_to = managers.navigation:pad_out_position(retreat_to)
	end
	
	if not retreat_to or mvec3_dis_sq(retreat_to, from_pos) < 3600 then
		return
	end
	
	

	CopLogicAttack._cancel_cover_pathing(data, my_data)

	local new_action_data = {
		variant = "walk",
		body_part = 2,
		type = "walk",
		nav_path = {
			from_pos,
			retreat_to
		}
	}
	my_data.advancing = data.unit:brain():action_request(new_action_data)

	if my_data.advancing then
		my_data.retreating = true

		return true
	end

	return false
end

function CopLogicAttack._upd_combat_movement(data)
	local my_data = data.internal_data
	local unit = data.unit
	local t = data.t
	local focus_enemy = data.attention_obj
	local enemy_visible = focus_enemy.verified
	local enemy_spotted_last_2sec = focus_enemy.verified_t and t - focus_enemy.verified_t < 2
	local enemy_spotted_last_7sec = focus_enemy.verified_t and t - focus_enemy.verified_t < 7
	local action_taken = data.logic.action_taken(data, my_data)
	action_taken = action_taken or CopLogicAttack._upd_pose(data, my_data)
	local in_cover = my_data.in_cover
	local want_to_take_cover = my_data.want_to_take_cover
	local move_to_cover = false
	local want_flank_cover = false

	if not my_data.peek_to_shoot_allowed and not enemy_spotted_last_2sec then
		my_data.peek_to_shoot_allowed = true
	end

	if my_data.stay_out_time and (enemy_spotted_last_2sec or not my_data.at_cover_shoot_pos or action_taken or want_to_take_cover) then
		my_data.stay_out_time = nil
	elseif my_data.attitude == "engage" and not my_data.stay_out_time and my_data.at_cover_shoot_pos and not enemy_spotted_last_2sec and not action_taken and not want_to_take_cover then
		my_data.stay_out_time = t + 7
	end

	if action_taken then
		-- Nothing
	elseif want_to_take_cover then
		move_to_cover = true
	elseif not enemy_spotted_last_2sec or my_data.flank_cover and best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) then
		local can_charge = not my_data.charge_path_failed_t or data.t - my_data.charge_path_failed_t > 6
		
		if can_charge then
			if my_data.flank_cover and my_data.flank_cover.failed or my_data.attitude == "engage" and my_data.cover_enter_t and my_data.cover_enter_t > 5 then
				if my_data.charge_path then
					local path = my_data.charge_path
					my_data.charge_path = nil
					action_taken = CopLogicAttack._request_action_walk_to_cover_shoot_pos(data, my_data, path)
				elseif not my_data.charge_path_search_id and focus_enemy.nav_tracker then
					my_data.charge_pos = CopLogicAttack._find_flank_pos(data, my_data, focus_enemy.nav_tracker, my_data.weapon_range.optimal)

					if my_data.charge_pos then
						my_data.charge_path_search_id = "charge" .. tostring(data.key)
						my_data.charge_pos = managers.navigation:pad_out_position(my_data.charge_pos)

						unit:brain():search_for_path(my_data.charge_path_search_id, my_data.charge_pos, nil, nil, nil)
					else
						debug_pause_unit(data.unit, "failed to find charge_pos", data.unit)

						my_data.charge_path_failed_t = TimerManager:game():time()
					end
				end
			end
		end
		
		if not my_data.charge_path_search_id then
			if in_cover then
				if my_data.peek_to_shoot_allowed then
					local height = nil

					if in_cover[NavigationManager.COVER_RESERVED] then
						height = 150
					else
						height = 80
					end

					local my_tracker = data.unit:movement():nav_tracker()
					local shoot_from_pos = CopLogicAttack._peek_for_pos_sideways(data, my_data, my_tracker, focus_enemy.m_head_pos, height)

					if shoot_from_pos then
						shoot_from_pos = managers.navigation:pad_out_position(shoot_from_pos)
						
						local path = {
							my_tracker:position(),
							shoot_from_pos
						}
						action_taken = CopLogicAttack._request_action_walk_to_cover_shoot_pos(data, my_data, path, math.random() < 0.5 and "run" or "walk")
					else
						my_data.peek_to_shoot_allowed = false
					end
				else
					move_to_cover = true
					want_flank_cover = true
				end
			elseif my_data.walking_to_cover_shoot_pos then
				-- Nothing
			elseif my_data.at_cover_shoot_pos and my_data.stay_out_time and my_data.stay_out_time < t then
				move_to_cover = true
				
				if not enemy_spotted_last_2sec then
					want_flank_cover = true
				end
			else
				move_to_cover = true
			end
		end
	end

	local best_cover = my_data.best_cover

	if not action_taken and not my_data.processing_cover_path and not my_data.cover_path and not my_data.charge_path_search_id and best_cover and (not in_cover or best_cover[1] ~= in_cover[1]) and (not my_data.cover_path_failed_t or data.t - my_data.cover_path_failed_t > 5) then
		CopLogicAttack._cancel_cover_pathing(data, my_data)

		local search_id = tostring(data.unit:key()) .. "cover"

		if data.unit:brain():search_for_path_to_cover(search_id, best_cover[1], best_cover[NavigationManager.COVER_RESERVATION]) then
			my_data.cover_path_search_id = search_id
			my_data.processing_cover_path = best_cover
		end
	end

	if not action_taken and move_to_cover and my_data.cover_path then
		action_taken = CopLogicAttack._request_action_walk_to_cover(data, my_data)
	end

	if want_flank_cover then
		if not my_data.flank_cover then
			local sign = math.random() < 0.5 and -1 or 1
			local step = 30
			my_data.flank_cover = {
				step = step,
				angle = step * sign,
				sign = sign
			}
		end
	else
		my_data.flank_cover = nil
	end

	if data.important and not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") and CopLogicAttack._can_move(data) and enemy_visible and (not in_cover or not in_cover[NavigationManager.COVER_RESERVED]) then
		if data.is_suppressed and data.t - data.unit:character_damage():last_suppression_t() < 0.7 then
			action_taken = CopLogicBase.chk_start_action_dodge(data, "scared")
		end

		if not action_taken and focus_enemy.is_person and focus_enemy.dis < 2000 and (data.group and data.group.size > 1 or math.random() < 0.5) then
			local dodge = false

			if focus_enemy.is_local_player then
				local e_movement_state = focus_enemy.unit:movement():current_state()

				if not e_movement_state:_is_reloading() and not e_movement_state:_interacting() and not e_movement_state:is_equipping() then
					dodge = true
				end
			else
				local e_anim_data = focus_enemy.unit:anim_data()

				if (e_anim_data.move or e_anim_data.idle) and not e_anim_data.reload then
					dodge = true
				end
			end

			if dodge and focus_enemy.aimed_at then
				action_taken = CopLogicBase.chk_start_action_dodge(data, "preemptive")
			end
		end
	end

	if not action_taken and want_to_take_cover and not best_cover and CopLogicAttack._should_retreat(data, focus_enemy) then
		action_taken = CopLogicAttack._start_action_move_back(data, my_data, focus_enemy, false)
		
		if not my_data.flank_cover then --if they're having trouble finding cover because they're backed into a wall, rotating the direction at which they do it might help.
			local sign = math.random() < 0.5 and -1 or 1
			local step = 30
			my_data.flank_cover = {
				step = step,
				angle = step * sign,
				sign = sign
			}
		end
	end

	action_taken = action_taken or CopLogicAttack._start_action_move_out_of_the_way(data, my_data)
end

function CopLogicAttack._upd_enemy_detection(data, is_synchronous)
	managers.groupai:state():on_unit_detection_updated(data.unit)

	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local delay = CopLogicBase._upd_attention_obj_detection(data, AIAttentionObject.REACT_AIM, nil)
	local desired_attention, new_prio_slot, new_reaction = CopLogicBase._get_priority_attention(data, data.detected_attention_objects, nil)

	CopLogicBase._set_attention_obj(data, desired_attention, new_reaction)
	CopLogicAttack._chk_exit_attack_logic(data, new_reaction)

	if my_data ~= data.internal_data then
		return
	end

	local old_att_obj = data.attention_obj

	if desired_attention then
		if old_att_obj and old_att_obj.u_key ~= desired_attention.u_key then
			CopLogicAttack._cancel_charge(data, my_data)

			my_data.flank_cover = nil

			if not data.unit:movement():chk_action_forbidden("walk") then
				CopLogicAttack._cancel_walking_to_cover(data, my_data)
			end

			CopLogicAttack._set_best_cover(data, my_data, nil)
		end
	elseif old_att_obj then
		CopLogicAttack._cancel_charge(data, my_data)

		my_data.flank_cover = nil
	end

	CopLogicBase._chk_call_the_police(data)

	if my_data ~= data.internal_data then
		return
	end

	data.logic._upd_aim(data, my_data)

	if not is_synchronous then
		CopLogicBase.queue_task(my_data, my_data.detection_task_key, CopLogicAttack._upd_enemy_detection, data, delay and data.t + delay, data.important and true)
	end

	CopLogicBase._report_detections(data.detected_attention_objects)
end

function CopLogicAttack._upd_aim(data, my_data)
	local shoot, aim, expected_pos = nil
	local focus_enemy = data.attention_obj

	if not my_data.weapon_range then
		my_data.weapon_range = {
			close = 10000,
			optimal = 15000,
			far = 20000
		}
	end

	if focus_enemy and AIAttentionObject.REACT_AIM <= focus_enemy.reaction then
		local last_sup_t = data.unit:character_damage():last_suppression_t()

		if not data.char_tweak.always_face_enemy and data.unit:anim_data().run and my_data.weapon_range.close < focus_enemy.dis then
			local walk_to_pos = data.unit:movement():get_walk_to_pos()

			if walk_to_pos then
				mvector3.direction(temp_vec1, data.m_pos, walk_to_pos)
				mvector3.direction(temp_vec2, data.m_pos, focus_enemy.m_pos)

				local dot = mvector3.dot(temp_vec1, temp_vec2)

				if dot < 0.6 then
					shoot = false
					aim = false
				end
			end
		end
		
		if my_data.weapon_range_max and shoot == nil then
			if my_data.weapon_range_max < focus_enemy.dis then
				shoot = false
			end
		end

		if focus_enemy.verified or focus_enemy.nearly_visible then
			if aim == nil and AIAttentionObject.REACT_AIM <= focus_enemy.reaction then
				if AIAttentionObject.REACT_SHOOT <= focus_enemy.reaction and shoot == nil then
					local running = data.unit:anim_data().run

					if focus_enemy.verified then
						shoot = true
					else
						local time_since_verification = focus_enemy.verified_t and data.t - focus_enemy.verified_t

						if my_data.firing and time_since_verification and time_since_verification < 3.5 then
							shoot = true
						end
					end

					aim = aim or shoot
				else
					aim = true
				end
			end
		elseif aim == nil and AIAttentionObject.REACT_AIM <= focus_enemy.reaction then
			local time_since_verification = focus_enemy.verified_t and data.t - focus_enemy.verified_t
			local running = my_data.advancing and not my_data.advancing:stopping() and my_data.advancing:haste() == "run"
			local same_z = math.abs(focus_enemy.verified_pos.z - data.m_pos.z) < 250

			if running then
				if time_since_verification and time_since_verification < math.lerp(5, 1, math.max(0, focus_enemy.verified_dis - 500) / 600) then
					aim = true
				end
			else
				aim = true
			end

			if aim and shoot == nil and AIAttentionObject.REACT_SHOOT <= focus_enemy.reaction and time_since_verification and time_since_verification < (running and 2 or 3) then
				shoot = true
			end

			if not aim then
				--expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)

				if expected_pos then
					if running then
						local watch_dir = temp_vec1

						mvec3_set(watch_dir, expected_pos)
						mvec3_sub(watch_dir, data.m_pos)
						mvec3_set_z(watch_dir, 0)

						local watch_pos_dis = mvec3_norm(watch_dir)
						local walk_to_pos = data.unit:movement():get_walk_to_pos()
						local walk_vec = temp_vec2

						mvec3_set(walk_vec, walk_to_pos)
						mvec3_sub(walk_vec, data.m_pos)
						mvec3_set_z(walk_vec, 0)
						mvec3_norm(walk_vec)

						local watch_walk_dot = mvec3_dot(watch_dir, walk_vec)

						if watch_pos_dis < 500 or watch_pos_dis < 1000 and watch_walk_dot > 0.85 then
							aim = true
						end
					else
						aim = true
					end
				end
			end
		else
			--expected_pos = CopLogicAttack._get_expected_attention_position(data, my_data)

			if expected_pos then
				aim = true
			end
		end
	end

	local weapon_cooldown = false

	if shoot and my_data.additional_weapon_stats and my_data.additional_weapon_stats.shooting_duration then
		my_data.additional_weapon_stats.shooting_t = my_data.additional_weapon_stats.shooting_t or data.t + my_data.additional_weapon_stats.shooting_duration

		if my_data.additional_weapon_stats.shooting_t < data.t then
			local rand_shoot = my_data.additional_weapon_stats.shooting_duration + math.random(0, 100) / 150
			local rand_cooldown = my_data.additional_weapon_stats.cooldown_duration + math.random(0, 100) / 400
			my_data.additional_weapon_stats.shooting_t = data.t + rand_shoot + rand_shoot + rand_cooldown
			my_data.additional_weapon_stats.cooldown_t = data.t + rand_cooldown
		elseif my_data.additional_weapon_stats.cooldown_t and data.t < my_data.additional_weapon_stats.cooldown_t then
			weapon_cooldown = true
		end
	end

	if shoot and weapon_cooldown then
		shoot = false
	end

	if not aim and data.char_tweak.always_face_enemy and focus_enemy and AIAttentionObject.REACT_COMBAT <= focus_enemy.reaction then
		aim = true
	end

	if data.logic.chk_should_turn(data, my_data) and (focus_enemy or expected_pos) then
		local enemy_pos = expected_pos or (focus_enemy.verified or focus_enemy.nearly_visible) and focus_enemy.m_pos or focus_enemy.last_verified_pos or focus_enemy.verified_pos

		CopLogicAttack._request_action_turn_to_enemy(data, my_data, data.m_pos, enemy_pos)
	end

	if aim or shoot then
		if expected_pos then
			if my_data.attention_unit ~= expected_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(expected_pos))

				my_data.attention_unit = mvector3.copy(expected_pos)
			end
		elseif focus_enemy.verified or focus_enemy.nearly_visible then
			if my_data.attention_unit ~= focus_enemy.u_key then
				CopLogicBase._set_attention(data, focus_enemy)

				my_data.attention_unit = focus_enemy.u_key
			end
		else
			local look_pos = focus_enemy.last_verified_pos or focus_enemy.verified_pos

			if my_data.attention_unit ~= look_pos then
				CopLogicBase._set_attention_on_pos(data, mvector3.copy(look_pos))

				my_data.attention_unit = mvector3.copy(look_pos)
			end
		end

		if not my_data.shooting and not data.unit:anim_data().reload and not data.unit:movement():chk_action_forbidden("action") then
			local shoot_action = {
				body_part = 3,
				type = "shoot"
			}

			if data.unit:brain():action_request(shoot_action) then
				my_data.shooting = true
			end
		end
	else
		if my_data.shooting or not data.unit:movement():chk_action_forbidden("action") then
			local new_action = {
				body_part = 3,
				type = "idle"
			}


			data.unit:brain():action_request(new_action)
		end

		if my_data.attention_unit then
			CopLogicBase._reset_attention(data)

			my_data.attention_unit = nil
		end
	end

	CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
end

function CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
	local focus_enemy = data.attention_obj

	if shoot and not data.unit:movement():chk_action_forbidden("action") then
		if not my_data.firing then
			data.unit:movement():set_allow_fire(true)

			my_data.firing = true
		end
	elseif my_data.firing or data.unit:movement():chk_action_forbidden("action") then
		data.unit:movement():set_allow_fire(false)

		my_data.firing = nil
	end
end

function CopLogicAttack._find_cover(data, my_data, threat_pos)
	if my_data.processing_cover_path or my_data.charge_path_search_id then
		return
	end

	local want_to_take_cover = my_data.want_to_take_cover
	local flank_cover = my_data.flank_cover
	local best_cover = my_data.best_cover
	local min_dis, max_dis = nil

	if want_to_take_cover then
		min_dis = math.max(data.attention_obj.dis * 0.9, data.attention_obj.dis - 200)
	elseif my_data.cover_enter_t and data.t - my_data.cover_enter_t > 5 then
		max_dis = math.max(data.attention_obj.dis * 0.9, data.attention_obj.dis - 200)
	end
	
	local continue = true
	local verify_cover = true
	
	if not flank_cover and best_cover then
		if my_data.in_cover and my_data.in_cover[1] == best_cover[1] and not my_data.in_cover[3] then
			verify_cover = nil
		end
		
		if verify_cover and not CopLogicAttack._verify_cover(best_cover[1], threat_pos, min_dis, max_dis) then
			continue = nil
		end
	end
	
	if not continue then
		return
	end

	local target_to_unit_vec = data.m_pos - threat_pos

	if flank_cover then
		local angle = flank_cover.angle
		local sign = flank_cover.sign

		if math.sign(angle) ~= sign then
			angle = -angle + flank_cover.step * sign

			if math.abs(angle) > 90 then
				flank_cover.failed = true
			else
				flank_cover.angle = angle
			end
		else
			flank_cover.angle = -angle
		end

		if not flank_cover.failed then
			mvector3.rotate_with(target_to_unit_vec, Rotation(flank_cover.angle))
		end
	end

	local optimal_distance = target_to_unit_vec:length()

	if want_to_take_cover then
		if optimal_distance < my_data.weapon_range.far then
			optimal_distance = optimal_distance + 400

			mvector3.set_length(target_to_unit_vec, optimal_distance)
		end

		max_dis = math.max(optimal_distance + 800, my_data.weapon_range.far)
	elseif optimal_distance > my_data.weapon_range.optimal * 1.2 then
		optimal_distance = my_data.weapon_range.optimal

		mvector3.set_length(target_to_unit_vec, optimal_distance)

		max_dis = my_data.weapon_range.far
	elseif max_dis then
		optimal_distance = math.max(max_dis * 0.9, max_dis - 100)

		mvector3.set_length(target_to_unit_vec, optimal_distance)
	end

	local optimal_position = threat_pos + target_to_unit_vec

	mvector3.set_length(target_to_unit_vec, max_dis)

	local furthest_position = threat_pos + target_to_unit_vec

	local cone_angle = nil

	if flank_cover then
		cone_angle = flank_cover.step
	else
		cone_angle = math.lerp(90, 30, math.min(1, optimal_distance / 3000))
	end

	local search_nav_seg = nil

	if data.objective and data.objective.type == "defend_area" then
		search_nav_seg = data.objective.area and data.objective.area.nav_segs or data.objective.nav_seg
	end

	local found_cover = managers.navigation:find_cover_in_cone_from_threat_pos(threat_pos, furthest_position, optimal_position, cone_angle, search_nav_seg, data.pos_rsrv_id)

	if found_cover and (not best_cover or CopLogicAttack._verify_cover(found_cover, threat_pos, min_dis, max_dis)) then
		local better_cover = {
			found_cover
		}

		CopLogicAttack._set_best_cover(data, my_data, better_cover)

		local offset_pos = CopLogicAttack._get_cover_offset_pos(data, better_cover, threat_pos)

		if offset_pos then
			offset_pos = managers.navigation:pad_out_position(offset_pos)
			
			better_cover[NavigationManager.COVER_RESERVATION] = offset_pos
		end
	else
		if flank_cover then
			flank_cover.failed = true
		end
		
		CopLogicAttack._set_best_cover(data, my_data, nil)

		my_data.cover_path_failed_t = TimerManager:game():time()
	end
end

function CopLogicAttack._process_pathing_results(data, my_data)
	if not data.pathing_results then
		return
	end

	local pathing_results = data.pathing_results
	local path = pathing_results[my_data.cover_path_search_id]

	if path then
		if path ~= "failed" then
			my_data.cover_path = path
		else
			CopLogicAttack._set_best_cover(data, my_data, nil)

			my_data.cover_path_failed_t = TimerManager:game():time()
		end

		my_data.processing_cover_path = nil
		my_data.cover_path_search_id = nil
	end

	path = pathing_results[my_data.charge_path_search_id]

	if path then
		if path ~= "failed" then
			my_data.charge_path = path
		else
			my_data.charge_path_failed_t = TimerManager:game():time()
		end

		my_data.charge_path_search_id = nil
	end

	path = pathing_results[my_data.expected_pos_path_search_id]

	if path then
		if path ~= "failed" then
			my_data.expected_pos_path = path
		end

		my_data.expected_pos_path_search_id = nil
	end

	data.pathing_results = nil
end

function CopLogicAttack._adjust_path_start_pos(data, path)
	local first_nav_point = path[1]
	local my_pos = data.m_pos

	if first_nav_point.x ~= my_pos.x or first_nav_point.y ~= my_pos.y then
		local ray_params = {
			allow_entry = true,
			pos_from = my_pos,
			pos_to = path[2]
		}

		if not managers.navigation:raycast(ray_params) then
			path[1] = mvector3.copy(my_pos)
		else
			table.insert(path, 1, mvector3.copy(my_pos))
		end
	end
	
	path = CopLogicBase:_optimize_path(path, data)
end

function CopLogicAttack._update_cover(data)
	local my_data = data.internal_data
	local cover_release_dis_sq = 10000
	local best_cover = my_data.best_cover

	if not data.attention_obj or not data.attention_obj.nav_tracker or AIAttentionObject.REACT_COMBAT > data.attention_obj.reaction then
		if best_cover and cover_release_dis_sq < mvector3.distance_sq(best_cover[1][NavigationManager.COVER_POSITION], data.m_pos) then
			CopLogicAttack._set_best_cover(data, my_data, nil)
		end

		return
	end

	local in_cover = my_data.in_cover
	local find_new = not my_data.moving_to_cover and not my_data.walking_to_cover_shoot_pos and not my_data.retreating

	if not find_new then
		if in_cover then
			if cover_release_dis_sq < mvector3.distance_sq(in_cover[1][NavigationManager.COVER_POSITION], data.m_pos) then
				my_data.in_cover = nil
				in_cover = nil
			else
				local threat_pos = data.attention_obj.verified_pos
				in_cover[NavigationManager.COVER_TRACKER], in_cover[NavigationManager.COVER_RESERVED] = CopLogicAttack._chk_covered(data, data.m_pos, threat_pos, data.visibility_slotmask)
			end
		end

		return
	end

	local enemy_tracker = data.attention_obj.nav_tracker
	local threat_pos = enemy_tracker:field_position()

	if data.objective and data.objective.type == "follow" then
		CopLogicAttack._find_cover_for_follow(data, my_data, threat_pos)
	else
		CopLogicAttack._find_cover(data, my_data, threat_pos)
	end

	if in_cover then
		if cover_release_dis_sq < mvector3.distance_sq(in_cover[1][NavigationManager.COVER_POSITION], data.m_pos) then
			my_data.in_cover = nil
			in_cover = nil
		else
			local threat_pos = data.attention_obj.verified_pos
			in_cover[NavigationManager.COVER_TRACKER], in_cover[NavigationManager.COVER_RESERVED] = CopLogicAttack._chk_covered(data, data.m_pos, threat_pos, data.visibility_slotmask)
		end
	end
end

function CopLogicAttack.aim_allow_fire(shoot, aim, data, my_data)
	local focus_enemy = data.attention_obj

	if shoot and (not data.char_tweak.shoot_logic_req or data.name == data.char_tweak.shoot_logic_req) then
		if not my_data.firing then
			data.unit:movement():set_allow_fire(true)

			my_data.firing = true

			if not data.unit:in_slot(16) and data.char_tweak.chatter.aggressive then
				managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "aggressive")
			end
		end
	elseif my_data.firing then
		data.unit:movement():set_allow_fire(false)

		my_data.firing = nil
	end
end