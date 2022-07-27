local mvec3_set = mvector3.set
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_negate = mvector3.negate
local mvec3_len = mvector3.length
local mvec3_cpy = mvector3.copy
local mvec3_set_length = mvector3.set_length
local mvec3_rotate_with = mvector3.rotate_with

local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local tmp_vec4 = Vector3()

local math_lerp = math.lerp
local math_random = math.random
local math_up = math.UP
local math_abs = math.abs
local math_min = math.min
local math_sign = math.sign
local math_floor = math.floor

local pairs_g = pairs
local next_g = next
local table_insert = table.insert
local table_remove = table.remove

function CopLogicTravel.enter(data, new_logic_name, enter_params)
	if not data.objective then
		return
	end

	local my_data = {
		unit = data.unit
	}

	CopLogicBase.enter(data, new_logic_name, enter_params, my_data)
	data.unit:brain():cancel_all_pathing_searches()

	local old_internal_data = data.internal_data
	local is_cool = data.unit:movement():cool()

	if is_cool then
		my_data.detection = data.char_tweak.detection.ntl
		my_data.vision = data.char_tweak.vision.idle
	else
		my_data.detection = data.char_tweak.detection.recon
		my_data.vision = data.char_tweak.vision.combat
	end

	if old_internal_data then
		my_data.turning = old_internal_data.turning
		my_data.firing = old_internal_data.firing
		my_data.shooting = old_internal_data.shooting
		my_data.attention_unit = old_internal_data.attention_unit
	end

	if data.char_tweak.announce_incomming then
		my_data.announce_t = data.t + 2
	end

	data.internal_data = my_data
	local key_str = tostring(data.key)
	my_data.upd_task_key = "CopLogicTravel.queued_update" .. key_str
	my_data.cover_update_task_key = "CopLogicTravel._update_cover" .. key_str

	if my_data.nearest_cover or my_data.best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 1)
	end

	my_data.advance_path_search_id = "CopLogicTravel_detailed" .. tostring(data.key)
	my_data.coarse_path_search_id = "CopLogicTravel_coarse" .. tostring(data.key)

	CopLogicBase._chk_has_old_action(data, my_data)

	local objective = data.objective
	local path_data = objective.path_data

	if objective.path_style == "warp" then
		my_data.warp_pos = objective.pos
	elseif path_data then
		local path_style = objective.path_style

		if path_style == "precise" then
			local path = {
				mvector3.copy(data.m_pos)
			}

			for _, point in ipairs(path_data.points) do
				table.insert(path, mvector3.copy(point.position))
			end

			my_data.advance_path = path
			my_data.coarse_path_index = 1
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			local end_pos = mvector3.copy(path[#path])
			local end_seg = managers.navigation:get_nav_seg_from_pos(end_pos)
			my_data.coarse_path = {
				{
					start_seg
				},
				{
					end_seg,
					end_pos
				}
			}
			my_data.path_is_precise = true
		elseif path_style == "coarse" then
			local nav_manager = managers.navigation
			local f_get_nav_seg = nav_manager.get_nav_seg_from_pos
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			local path = {
				{
					start_seg
				}
			}

			for _, point in ipairs(path_data.points) do
				local pos = mvector3.copy(point.position)
				local nav_seg = f_get_nav_seg(nav_manager, pos)

				table.insert(path, {
					nav_seg,
					pos
				})
			end

			my_data.coarse_path = path
			local i = CopLogicTravel.complete_coarse_path(data, my_data, path)

			if not i then
				Application:debug("[CopLogicTravel.enter1] coarse_path_index is nill?", inspect(my_data.coarse_path))

				my_data.coarse_path_index = 1
			else
				my_data.coarse_path_index = i
			end
		elseif path_style == "coarse_complete" then
			my_data.coarse_path = deep_clone(objective.path_data)
			local i = CopLogicTravel.complete_coarse_path(data, my_data, my_data.coarse_path)

			if not i then
				Application:debug("[CopLogicTravel.enter2] coarse_path_index is nill?", inspect(my_data.coarse_path))

				my_data.coarse_path_index = 1
			else
				my_data.coarse_path_index = i
			end
		end
	end

	if objective.stance then
		local upper_body_action = data.unit:movement()._active_actions[3]

		if not upper_body_action or upper_body_action:type() ~= "shoot" then
			data.unit:movement():set_stance(objective.stance)
		end
	end

	if data.attention_obj and AIAttentionObject.REACT_AIM < data.attention_obj.reaction then
		data.unit:movement():set_cool(false, managers.groupai:state().analyse_giveaway(data.unit:base()._tweak_table, data.attention_obj.unit))
	end

	if is_cool then
		data.unit:brain():set_attention_settings({
			peaceful = true
		})
	else
		data.unit:brain():set_attention_settings({
			cbt = true
		})
	end

	my_data.attitude = data.objective.attitude or "engage"
	my_data.weapon_range = data.char_tweak.weapon[data.unit:inventory():equipped_unit():base():weapon_tweak_data().usage].range
	my_data.weapon_range_max = data.char_tweak.weapon[data.unit:inventory():equipped_unit():base():weapon_tweak_data().usage].max_range
	my_data.additional_weapon_stats = data.char_tweak.weapon[data.unit:inventory():equipped_unit():base():weapon_tweak_data().usage].additional_weapon_stats
	my_data.path_safely = my_data.attitude == "avoid" and data.team.foes[tweak_data.levels:get_default_team_ID("player")]
	my_data.path_ahead = data.objective.path_ahead or data.team.id == tweak_data.levels:get_default_team_ID("player")

	data.unit:brain():set_update_enabled_state(false)

	if Application:production_build() then
		my_data.pathing_debug = {
			from_pos = Vector3(),
			to_pos = Vector3()
		}
	end
	
	CopLogicTravel.queued_update(data, my_data)
end

function CopLogicTravel.get_pathing_prio(data)
	local prio = nil
	local objective = data.objective

	if objective then
		prio = 0

		if objective.type == "phalanx" then
			prio = 4
		elseif objective.follow_unit then
			if objective.follow_unit:base().is_local_player or objective.follow_unit:base().is_husk_player then
				prio = 4
			end
		end
	end

	if prio or data.is_converted or data.internal_data and data.internal_data.criminal or data.unit:in_slot(16) then
		if data.is_converted or data.internal_data and data.internal_data.criminal or data.unit:in_slot(16) then
			prio = prio or 0

			prio = prio + 3
		elseif data.team.id == tweak_data.levels:get_default_team_ID("player") then
			prio = prio or 0

			prio = prio + 2
		elseif data.important then
			prio = prio + 1
		end
	end

	return prio
end

function CopLogicTravel._pathing_complete_clbk(data)
	local my_data = data.internal_data

	if not my_data.exiting then
		if my_data.processing_advance_path or my_data.processing_coarse_path then
			CopLogicTravel.upd_advance(data)
		end
	end
end

function CopLogicTravel._get_exact_move_pos(data, nav_index)
	local my_data = data.internal_data
	local objective = data.objective
	local to_pos = nil
	local coarse_path = my_data.coarse_path
	local total_nav_points = #coarse_path
	local reservation, wants_reservation = nil

	if total_nav_points <= nav_index then
		local new_occupation = data.logic._determine_destination_occupation(data, objective)

		if new_occupation then
			if new_occupation.type == "guard" then
				local guard_door = new_occupation.door
				local guard_pos = CopLogicTravel._get_pos_accross_door(guard_door, objective.nav_seg)

				if guard_pos then
					reservation = CopLogicTravel._reserve_pos_along_vec(guard_door.center, guard_pos)

					if reservation then
						local guard_object = {
							type = "door",
							door = guard_door,
							from_seg = new_occupation.from_seg
						}
						objective.guard_obj = guard_object
						to_pos = reservation.pos
					end
				end
			elseif new_occupation.type == "defend" then
				if new_occupation.cover then
					to_pos = new_occupation.cover[1][NavigationManager.COVER_POSITION]

					if data.char_tweak.wall_fwd_offset then
						to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, new_occupation.cover[1], data.char_tweak.wall_fwd_offset)
					end
					
					to_pos = managers.navigation:pad_out_position(to_pos, 4, data.char_tweak.wall_fwd_offset)

					if my_data.moving_to_cover then
						managers.navigation:release_cover(my_data.moving_to_cover[1])
					end

					local new_cover = new_occupation.cover

					managers.navigation:reserve_cover(new_cover[1], data.pos_rsrv_id)

					my_data.moving_to_cover = new_cover
				elseif new_occupation.pos then
					to_pos = new_occupation.pos
				end

				wants_reservation = true
			elseif new_occupation.type == "act" then
				to_pos = new_occupation.pos
				wants_reservation = true
			elseif new_occupation.type == "revive" then
				to_pos = new_occupation.pos
				objective.rot = new_occupation.rot
				wants_reservation = true
			else
				to_pos = new_occupation.pos
				wants_reservation = true
			end
		end

		if not to_pos then
			to_pos = managers.navigation:find_random_position_in_segment(objective.nav_seg)
			to_pos = CopLogicTravel._get_pos_on_wall(to_pos)
			to_pos = managers.navigation:pad_out_position(to_pos, 4, data.char_tweak.wall_fwd_offset)
			
			wants_reservation = true
		end
	else
		if my_data.moving_to_cover then
			managers.navigation:release_cover(my_data.moving_to_cover[1])

			my_data.moving_to_cover = nil
		end

		local nav_seg = coarse_path[nav_index][1]
		local area = managers.groupai:state():get_area_from_nav_seg_id(nav_seg)

		if not area then
			return nil
		end
		
		local needs_cover = not data.cool
		local cover = needs_cover and CopLogicTravel._find_cover(data, nav_seg, nil)

		if cover then
			managers.navigation:reserve_cover(cover, data.pos_rsrv_id)

			my_data.moving_to_cover = {
				cover
			}
			to_pos = cover[1]
			
			if data.char_tweak.wall_fwd_offset then
				to_pos = CopLogicTravel.apply_wall_offset_to_cover(data, my_data, cover, data.char_tweak.wall_fwd_offset)
			end
			
			to_pos = managers.navigation:pad_out_position(to_pos, 4, data.char_tweak.wall_fwd_offset)
		else
			to_pos = coarse_path[nav_index][2] or area.pos
			local pos_rsrv_id = data.pos_rsrv_id
			local rsrv_desc = {
				position = to_pos,
				radius = 60,
				filter = pos_rsrv_id
			}

			if not managers.navigation:is_pos_free(rsrv_desc) then
				to_pos = CopLogicTravel._find_near_free_pos(to_pos, 700, nil, pos_rsrv_id)
			end
			
			to_pos = managers.navigation:pad_out_position(to_pos, 4, data.char_tweak.wall_fwd_offset)
			
			wants_reservation = true
		end
	end

	if not reservation and wants_reservation then
		data.brain:add_pos_rsrv("path", {
			radius = 60,
			position = mvector3.copy(to_pos)
		})
	end

	return to_pos
end

function CopLogicTravel.chk_group_ready_to_move(data, my_data)
	local my_objective = data.objective

	if not my_objective.grp_objective then
		return true
	end

	local my_dis = mvector3.distance_sq(my_objective.area.pos, data.m_pos)
	
	if my_dis > 4000000 then
		return true
	end

	my_dis = my_dis * 1.15 * 1.15

	local can_continue = true

	for u_key, u_data in pairs(data.group.units) do
		if u_key ~= data.key then
			local his_objective = u_data.unit:brain():objective()

			if his_objective and his_objective.grp_objective == my_objective.grp_objective and not his_objective.in_place then
				if his_objective.is_default then
					can_continue = nil
					
					break
				else
					local his_dis = mvector3.distance_sq(his_objective.area.pos, u_data.m_pos)

					if my_dis < his_dis then
						can_continue = nil
						
						break
					end
				end
			end
		end
	end
	
	if not can_continue then
		if data.char_tweak.chatter and data.char_tweak.chatter.follow_me then
			managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "follow_me")
		end
	end

	return can_continue
end

function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
	local objective = data.objective

	if not objective or objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		return
	end

	if not my_data.coarse_path_index or my_data.coarse_path and #my_data.coarse_path - 1 == 1 then
		return
	end
	
	if my_data.criminal or data.unit:in_slot(16) or data.team.id == tweak_data.levels:get_default_team_ID("player") or data.team.friends[tweak_data.levels:get_default_team_ID("player")] then
		local follow_unit = objective.follow_unit
		local my_nav_seg_id = data.unit:movement():nav_tracker():nav_segment()
		local my_areas = managers.groupai:state():get_areas_from_nav_seg_id(my_nav_seg_id)
		local follow_unit_nav_seg_id = follow_unit:movement():nav_tracker():nav_segment()
		local should_try_stop = nil

		for _, area in ipairs(my_areas) do
			if area.nav_segs[follow_unit_nav_seg_id] then
				should_try_stop = true
				
				break
			end
		end
		
		if should_try_stop and not TeamAILogicIdle._check_should_relocate(data, my_data, data.objective) then
			objective.in_place = true

			data.logic.on_new_objective(data)
			
			return
		else
			local obj_nav_seg = my_data.coarse_path[#my_data.coarse_path][1]
			local obj_areas = managers.groupai:state():get_areas_from_nav_seg_id(obj_nav_seg)
			local dontcheckdis, dis
			
			for _, area in ipairs(obj_areas) do
				if area.nav_segs[follow_unit_nav_seg_id] then
					dontcheckdis = true
					
					break
				end
			end
			
			if not dontcheckdis and #obj_areas > 0 then
				if mvector3.distance_sq(obj_areas[1].pos, follow_unit:movement():nav_tracker():field_position()) > 1000000 or math.abs(obj_areas[1].pos.z - follow_unit:movement():nav_tracker():field_position().z) > 250 then
					objective.in_place = nil
					
					data.logic.on_new_objective(data)
			
					return
				end
			end
		end
	else
		local follow_unit = data.objective.follow_unit
		local advance_pos = follow_unit:brain() and follow_unit:brain():is_advancing()
		local follow_unit_pos = advance_pos or follow_unit:movement():m_pos()
		local relocate = nil
		
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
		
		if not relocate then
			objective.in_place = true

			data.logic.on_new_objective(data)
			
			return
		end
	end
end

function CopLogicTravel._determine_destination_occupation(data, objective)
	local occupation = nil

	if objective.type == "defend_area" then
		if objective.cover then
			occupation = {
				type = "defend",
				seg = objective.nav_seg,
				cover = objective.cover,
				radius = objective.radius
			}
		elseif objective.pos then
			occupation = {
				type = "defend",
				seg = objective.nav_seg,
				pos = objective.pos,
				radius = objective.radius
			}
		else
			local near_pos = objective.follow_unit and objective.follow_unit:movement():nav_tracker():field_position()
			local cover = CopLogicTravel._find_cover(data, objective.nav_seg, near_pos)

			if cover then
				local cover_entry = {
					cover
				}
				occupation = {
					type = "defend",
					seg = objective.nav_seg,
					cover = cover_entry,
					radius = objective.radius
				}
			else
				local nav_seg = managers.navigation._nav_segments[objective.nav_seg]

				if nav_seg then
					near_pos = CopLogicTravel._get_pos_on_wall(near_pos or nav_seg.pos, 700)
					near_pos = managers.navigation:pad_out_position(near_pos, 4, data.char_tweak.wall_fwd_offset)
					occupation = {
						type = "defend",
						seg = objective.nav_seg,
						pos = near_pos,
						radius = objective.radius
					}
				else
					debug_pause("[CopLogicTravel._determine_destination_occupation] Can't find nav_seg for the objective!?", inspect(objective), inspect(managers.navigation._nav_segments))
				end
			end
		end
	elseif objective.type == "phalanx" then
		local logic = data.unit:brain():get_logic_by_name(objective.type)

		logic.register_in_group_ai(data.unit)

		local phalanx_circle_pos = logic.calc_initial_phalanx_pos(data.m_pos, objective)
		occupation = {
			type = "defend",
			seg = objective.nav_seg,
			pos = phalanx_circle_pos,
			radius = objective.radius
		}
	elseif objective.type == "act" then
		occupation = {
			type = "act",
			seg = objective.nav_seg,
			pos = objective.pos
		}
	elseif objective.type == "follow" then
		local my_data = data.internal_data
		local follow_tracker = objective.follow_unit:movement():nav_tracker()
		local dest_nav_seg_id = my_data.coarse_path[#my_data.coarse_path][1]
		local dest_area = managers.groupai:state():get_area_from_nav_seg_id(dest_nav_seg_id)
		local follow_pos = follow_tracker:field_position()
		local threat_pos = nil

		if data.attention_obj and data.attention_obj.nav_tracker and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
			threat_pos = data.attention_obj.nav_tracker:field_position()
		end

		local cover = managers.navigation:find_cover_in_nav_seg_3(dest_area.nav_segs, 600, follow_pos, threat_pos)

		if cover then
			local cover_entry = {
				cover
			}
			occupation = {
				type = "defend",
				cover = cover_entry
			}
		else
			local max_dist = 600

			if objective.called then
				max_dist = 450
			end

			local to_pos = CopLogicTravel._get_pos_on_wall(follow_pos or dest_area.pos, max_dist)
			to_pos = managers.navigation:pad_out_position(to_pos, 4, data.char_tweak.wall_fwd_offset)
			occupation = {
				type = "defend",
				pos = to_pos
			}
		end
	elseif objective.type == "revive" then
		local is_local_player = objective.follow_unit:base().is_local_player
		local revive_u_mv = objective.follow_unit:movement()
		local revive_u_tracker = revive_u_mv:nav_tracker()
		local revive_u_rot = is_local_player and Rotation(0, 0, 0) or revive_u_mv:m_rot()
		local revive_u_fwd = revive_u_rot:y()
		local revive_u_right = revive_u_rot:x()
		local revive_u_pos = revive_u_tracker:lost() and revive_u_tracker:field_position() or revive_u_mv:m_pos()
		local ray_params = {
			trace = true,
			tracker_from = revive_u_tracker
		}

		if revive_u_tracker:lost() then
			ray_params.pos_from = revive_u_pos
		end

		local stand_dis = nil

		if is_local_player or objective.follow_unit:base().is_husk_player then
			stand_dis = 120
		else
			stand_dis = 90
			local mid_pos = mvector3.copy(revive_u_fwd)

			mvector3.multiply(mid_pos, -20)
			mvector3.add(mid_pos, revive_u_pos)

			ray_params.pos_to = mid_pos
			local ray_res = managers.navigation:raycast(ray_params)
			revive_u_pos = ray_params.trace[1]
		end

		local rand_side_mul = math.random() > 0.5 and 1 or -1
		local revive_pos = mvector3.copy(revive_u_right)

		mvector3.multiply(revive_pos, rand_side_mul * stand_dis)
		mvector3.add(revive_pos, revive_u_pos)

		ray_params.pos_to = revive_pos
		local ray_res = managers.navigation:raycast(ray_params)

		if ray_res then
			local opposite_pos = mvector3.copy(revive_u_right)

			mvector3.multiply(opposite_pos, -rand_side_mul * stand_dis)
			mvector3.add(opposite_pos, revive_u_pos)

			ray_params.pos_to = opposite_pos
			local old_trace = ray_params.trace[1]
			local opposite_ray_res = managers.navigation:raycast(ray_params)

			if opposite_ray_res then
				if mvector3.distance(revive_pos, revive_u_pos) < mvector3.distance(ray_params.trace[1], revive_u_pos) then
					revive_pos = ray_params.trace[1]
				else
					revive_pos = old_trace
				end
			else
				revive_pos = ray_params.trace[1]
			end
		else
			revive_pos = ray_params.trace[1]
		end

		local revive_rot = revive_u_pos - revive_pos
		local revive_rot = Rotation(revive_rot, math.UP)
		occupation = {
			type = "revive",
			pos = revive_pos,
			rot = revive_rot
		}
	else
		occupation = {
			seg = objective.nav_seg,
			pos = objective.pos
		}
		
		if objective.pos then
			if objective.type == "sniper" then
				occupation.pos = managers.navigation:pad_out_position(occupation.pos, 4)
			end
		end
	end

	return occupation
end

function CopLogicTravel.upd_advance(data)
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()
	data.t = t

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
		
		if my_data.old_action then
			return
		end
	end
	
	if fuckyou then
		if my_data.cover_leave_t then
			if not my_data.turning and not unit:movement():chk_action_forbidden("walk") and not data.unit:anim_data().reload then
				if my_data.cover_leave_t < t then
					my_data.cover_leave_t = nil
				elseif data.attention_obj and AIAttentionObject.REACT_SCARED <= data.attention_obj.reaction and (not my_data.best_cover or not my_data.best_cover[NavigationManager.COVER_RESERVED]) and not unit:anim_data().crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
					CopLogicAttack._request_action_crouch(data)
				end
			end
			
			if my_data.cover_leave_t then 
				return
			end
		end
	end
	
	if my_data.warp_pos then
		data.unit:movement():set_position(objective.pos)

		if objective.rot then
			data.unit:movement():set_rotation(objective.rot)
		end

		CopLogicTravel._on_destination_reached(data)
	elseif my_data.advancing then
		if my_data.coarse_path then
			if my_data.announce_t and my_data.announce_t < t then
				CopLogicTravel._try_anounce(data, my_data)
			end

			CopLogicTravel._chk_stop_for_follow_unit(data, my_data)

			if my_data ~= data.internal_data then
				return
			end
		end
	elseif my_data.advance_path then
		CopLogicTravel._chk_begin_advance(data, my_data)

		if my_data.advancing then
			CopLogicTravel._check_start_path_ahead(data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._upd_pathing(data, my_data)

		if my_data ~= data.internal_data then
			return
		end
	elseif objective and (objective.nav_seg or objective.type == "follow") then
		local path_ok = CopLogicTravel._verifiy_coarse_path(objective.nav_seg, my_data.coarse_path)

		if my_data.coarse_path and path_ok then
			if my_data.coarse_path_index == #my_data.coarse_path then
				CopLogicTravel._on_destination_reached(data)

				return
			else
				CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
			end
		else
			CopLogicTravel._begin_coarse_pathing(data, my_data)
		end
	else
		CopLogicBase._exit(data.unit, "idle")

		return
	end
end

function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
	local objective = data.objective

	if not objective or objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		return
	end

	if not my_data.coarse_path_index or my_data.coarse_path and #my_data.coarse_path - 1 == 1 then
		return
	end
	
	if my_data.criminal or data.unit:in_slot(16) or data.team.id == tweak_data.levels:get_default_team_ID("player") or data.team.friends[tweak_data.levels:get_default_team_ID("player")] then
		local follow_unit = objective.follow_unit
		local my_nav_seg_id = data.unit:movement():nav_tracker():nav_segment()
		local my_areas = managers.groupai:state():get_areas_from_nav_seg_id(my_nav_seg_id)
		local follow_unit_nav_seg_id = follow_unit:movement():nav_tracker():nav_segment()
		local should_try_stop = nil

		for _, area in ipairs(my_areas) do
			if area.nav_segs[follow_unit_nav_seg_id] then
				should_try_stop = true
				
				break
			end
		end
		
		if should_try_stop and not TeamAILogicIdle._check_should_relocate(data, my_data, data.objective) then
			objective.in_place = true

			TeamAILogicBase._exit(data.unit, "idle")
			
			return
		else
			local obj_nav_seg = my_data.coarse_path[#my_data.coarse_path][1]
			local obj_areas = managers.groupai:state():get_areas_from_nav_seg_id(obj_nav_seg)
			local dontcheckdis, dis
			
			for _, area in ipairs(obj_areas) do
				if area.nav_segs[follow_unit_nav_seg_id] then
					dontcheckdis = true
					
					break
				end
			end
			
			if not dontcheckdis and #obj_areas > 0 then
				if mvector3.distance_sq(obj_areas[1].pos, follow_unit:movement():nav_tracker():field_position()) > 1000000 or math.abs(obj_areas[1].pos.z - follow_unit:movement():nav_tracker():field_position().z) > 250 then
					objective.in_place = nil

					TeamAILogicBase._exit(data.unit, "travel")
			
					return
				end
			end
		end
	else
		local follow_unit = data.objective.follow_unit
		local advance_pos = follow_unit:brain() and follow_unit:brain():is_advancing()
		local follow_unit_pos = advance_pos or follow_unit:movement():m_pos()
		local relocate = nil
		
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
		
		if not relocate then
			objective.in_place = true

			data.logic.on_new_objective(data)
			
			return
		end
	end
end

local free_pos_dirs = {
	Vector3(1, 1, 0),
	Vector3(1, -1, 0),
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(1, 0.5, 0),
	Vector3(0.5, 1, 0),
	Vector3(1, -0.5, 0),
	Vector3(0.5, -1, 0),
	Vector3(0.5, 0, 0),
	Vector3(0, 0.5, 0)
}

function CopLogicTravel._find_near_free_pos(from_pos, search_dis, max_recurse_i, pos_rsrv_id)
	max_recurse_i = max_recurse_i or 5
	
	if search_dis then
		search_dis = search_dis / max_recurse_i
	end
	
	search_dis = search_dis or 100

	local nav_manager = managers.navigation
	local nav_ray_f = nav_manager.raycast
	local pos_free_f = nav_manager.is_pos_free
	local fail_position, fail_position_dis, ray_res, traced_pos = nil
	local rsrv_desc = pos_rsrv_id and {
		radius = 60,
		filter = pos_rsrv_id
	} or {
		false,
		60
	}

	local to_pos, dir_vec = tmp_vec3, tmp_vec4
	local ray_params = {
		allow_entry = false,
		trace = true,
		pos_from = from_pos
	}
	local i, max_i, advance, recurse_i = 1, #free_pos_dirs, false, 0

	while true do
		local dir = free_pos_dirs[i]
		mvec3_set(dir_vec, dir)

		if advance then
			mvec3_negate(dir_vec)
		end

		mvec3_mul(dir_vec, search_dis)
		mvec3_set(to_pos, from_pos)
		mvec3_add(to_pos, dir_vec)

		ray_params.pos_to = to_pos
		ray_res = nav_ray_f(nav_manager, ray_params)
		traced_pos = ray_params.trace[1]

		if not ray_res then
			rsrv_desc.position = traced_pos

			if pos_free_f(nav_manager, rsrv_desc) then
				return traced_pos
			end
		elseif fail_position then
			local this_dis = mvec3_dis_sq(from_pos, traced_pos)

			if this_dis < fail_position_dis then
				rsrv_desc.position = traced_pos

				if pos_free_f(nav_manager, rsrv_desc) then
					fail_position = traced_pos
					fail_position_dis = this_dis
				end
			end
		else
			rsrv_desc.position = traced_pos

			if pos_free_f(nav_manager, rsrv_desc) then
				fail_position = traced_pos
				fail_position_dis = mvec3_dis_sq(from_pos, traced_pos)
			end
		end

		if not advance then
			advance = true
		else
			advance = false

			i = i + 1

			if i > max_i then
				recurse_i = recurse_i + 1

				if recurse_i > max_recurse_i then
					break
				else
					i = 1
					search_dis = search_dis + 100
				end
			end
		end
	end

	if fail_position then
		return fail_position
	end

	return from_pos
end