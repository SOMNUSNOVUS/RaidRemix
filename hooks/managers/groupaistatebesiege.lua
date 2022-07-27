Hooks:PostHook(GroupAIStateBesiege, "init", "raid_huntblacklist", function(self)
	self._current_job_id = "streaming_level"
end)

function GroupAIStateBesiege:_queue_police_upd_task()
	self._police_upd_task_queued = true
	
	if Network:is_server() then --essentially, if theres less players, more important enemies are allowed instead of just 3
		if not Global.game_settings.single_player then
			local new_value = 12 / table.size(self:all_player_criminals()) 

			self._nr_important_cops = new_value
		end
	end
	
	managers.enemy:add_delayed_clbk("GroupAIStateBesiege._upd_police_activity", callback(self, self, "_upd_police_activity"), self._t + (next(self._spawning_groups) and GroupAIStateBesiege._POLICE_UPDATE_INTERVAL_MIN or GroupAIStateBesiege._POLICE_UPDATE_INTERVAL_MAX))
end

function GroupAIStateBesiege:set_job_id(job_id)
	self._current_job_id = job_id 
	
	--log(tostring(job_id))
	
	local blacklisted_hunts = {
		ger_bridge = true,
		hunters = true,
		convoy = true,
		radio_defense = true
	}
	
	if blacklisted_hunts[job_id] then
		self._blacklisted_hunt = true
		--log("moo moo hunt")
	else
		self._blacklisted_hunt = nil
	end
end

function GroupAIStateBesiege:set_wave_mode(flag)
	if flag == "hunt" then
		if self._blacklisted_hunt then
			flag = "soft_hunt"
		end
	end

	local old_wave_mode = self._wave_mode
	self._wave_mode = flag
	self._hunt_mode = nil
	
	if flag == "soft_hunt" then
		--log("soft and tender hunt mode...")
		self._hunt_mode = true
		self._soft_hunt = true
		self._wave_mode = "besiege"

		managers.hud:start_assault()
		self:_set_rescue_state(false)
		self:set_assault_mode(true)
		managers.trade:set_trade_countdown(false)
		self:_end_regroup_task()

		if self._task_data.assault.active then
			self._task_data.assault.phase = "sustain"
			
			self._task_data.assault.phase_end_t = self._t + math.lerp(self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_min), self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_max), math.random()) * self:_get_balancing_multiplier(self._tweak_data.assault.sustain_duration_balance_mul)
			
			self._task_data.use_smoke = true
			self._task_data.use_smoke_timer = 0

			managers.music:raid_music_state_change("assault")
		else
			self._task_data.assault.next_dispatch_t = self._t
		end
	elseif flag == "hunt" then
		self._hunt_mode = true
		self._wave_mode = "besiege"

		managers.hud:start_assault()
		self:_set_rescue_state(false)
		self:set_assault_mode(true)
		managers.trade:set_trade_countdown(false)
		self:_end_regroup_task()

		if self._task_data.assault.active then
			self._task_data.assault.phase = "sustain"
			
			self._task_data.assault.phase_end_t = self._t + math.lerp(self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_min), self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_max), math.random()) * self:_get_balancing_multiplier(self._tweak_data.assault.sustain_duration_balance_mul)
			
			self._task_data.use_smoke = true
			self._task_data.use_smoke_timer = 0

			managers.music:raid_music_state_change("assault")
		else
			self._task_data.assault.next_dispatch_t = self._t
		end
	elseif flag == "besiege" then
		if self._task_data.regroup.active then
			self._task_data.assault.next_dispatch_t = self._task_data.regroup.end_t
		elseif not self._task_data.assault.active then
			self._task_data.assault.next_dispatch_t = self._t
		else
			local task_data = self._task_data.assault
			
			if task_data.phase == "anticipation" then
				managers.mission:call_global_event("start_assault")
				managers.hud:start_assault()
				self:_set_rescue_state(false)

				task_data.phase = "build"
				task_data.phase_end_t = self._t + self._tweak_data.assault.build_duration
				task_data.is_hesitating = nil

				self:set_assault_mode(true)
				managers.music:raid_music_state_change("assault")
				managers.trade:set_trade_countdown(false)
			elseif task_data.phase ~= "sustain" then
				task_data.phase = "sustain"
				task_data.phase_end_t = t + math.lerp(self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_min), self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_max), math.random()) * self:_get_balancing_multiplier(self._tweak_data.assault.sustain_duration_balance_mul)
			end
		end
	elseif flag == "quiet" then
		self._hunt_mode = nil
	else
		self._wave_mode = old_wave_mode

		debug_pause("[GroupAIStateBesiege:set_wave_mode] flag", flag, " does not apply to the current Group AI state.")
	end
end

function GroupAIStateBesiege:clean_up()
	managers.navigation:remove_listener(self:nav_ready_listener_key())

	if self._police_upd_task_queued then
		managers.enemy:remove_delayed_clbk("GroupAIStateBesiege._upd_police_activity")
	end

	if self._hostage_upd_key then
		managers.enemy:unqueue_task(self._hostage_upd_key)
	end

	self:_init_misc_data(true)
end

function GroupAIStateBesiege:on_simulation_ended()
	GroupAIStateBesiege.super.on_simulation_ended(self)

	if managers.navigation:is_data_ready() then
		self:_create_area_data()

		self._task_data = {
			reenforce = {
				next_dispatch_t = 0,
				tasks = {}
			},
			recon = {
				next_dispatch_t = 0,
				tasks = {}
			},
			assault = {
				is_first = true,
				disabled = true
			},
			regroup = {}
		}
	end

	if self._police_upd_task_queued then
		self._police_upd_task_queued = nil

		managers.enemy:remove_delayed_clbk("GroupAIStateBesiege._upd_police_activity")
	end
end

function GroupAIStateBesiege:_upd_assault_spawning(task_data, primary_target_area)
	local allowed_groups = nil
	local spawn_group_anyways = nil

	if self:_count_police_force("assault") < task_data.force + 12 then
		if managers.enemy:is_commander_active() then
			if not self._commander_spawned_groups or math.random() <= 0.5 then
				allowed_groups = {
					commander_squad = {
						100,
						100,
						100
					}
				}
				
				spawn_group_anyways = true
			end
		elseif self._commander_spawned_groups then
			self._commander_spawned_groups = nil
		end
	end

	local nr_wanted = task_data.force - self:_count_police_force("assault")

	if task_data.phase == "anticipation" then
		nr_wanted = nr_wanted - 5
	end

	if nr_wanted > 0 and task_data.phase ~= "fade" or spawn_group_anyways then
		if next(self._spawning_groups) then
			-- Nothing
		else
			allowed_groups = allowed_groups or self._tweak_data.assault.groups
	
			local spawn_group, group_nationality, spawn_group_type = self:_find_spawn_group_near_area(primary_target_area, allowed_groups, nil, nil, nil)

			if spawn_group then
				local attitude = "avoid"
				
				if task_data.phase ~= "anticipation" then
					attitude = "engage"
				end
			
				local grp_objective = {
					attitude = "avoid",
					stance = "hos",
					pose = "crouch",
					type = "assault_area",
					area = spawn_group.area
				}

				self:_spawn_in_group(spawn_group, group_nationality, spawn_group_type, grp_objective, task_data)
			end
		end
	end
end

function GroupAIStateBesiege:_assign_recon_groups_to_assault()
	local function suitable_grp_func(group)
		if group.objective.type == "recon_area" then
			local grp_objective = {
				stance = "hos",
				attitude = "avoid",
				pose = "crouch",
				type = "assault_area",
				area = group.objective.area
			}

			self:_set_objective_to_enemy_group(group, grp_objective)
		end
	end
	
	for group_id, group in pairs(self._groups) do
		suitable_grp_func(group)
	end
end

function GroupAIStateBesiege:_upd_assault_tasks()
	local task_data = self._task_data.assault
	
	if Network:is_server() then
		if self._hunt_mode and self._soft_hunt then
			if self._drama_data.amount > tweak_data.drama.assault_fade_end then
				self._hunt_mode = nil
				self._soft_hunt = nil
			end
		elseif self._fake_assault_mode then
			if self._t - self._fake_assault_mode_t > 60 then
				if self:_count_criminals_engaged_force(9) <= 8 and self._drama_data.amount <= tweak_data.drama.assault_fade_end then
					self:set_fake_assault_mode(false)
				end
			end
		end
	end

	if not task_data.active then
		return
	end

	local t = self._t

	self:_assign_recon_groups_to_assault()

	local force_pool = self:get_difficulty_dependent_value(self._tweak_data.assault.force_pool) * self:_get_balancing_multiplier(self._tweak_data.assault.force_pool_balance_mul)
	local task_spawn_allowance = force_pool - (self._hunt_mode and 0 or task_data.force_spawned)

	if task_data.phase == "anticipation" then
		if task_spawn_allowance <= 0 then
			task_data.phase = "fade"
			task_data.phase_end_t = t + self._tweak_data.assault.fade_duration
		elseif task_data.phase_end_t < t or self._drama_data.zone == "high" or self:_count_criminals_engaged_force(17) > 16 then
			managers.mission:call_global_event("start_assault")
			managers.hud:start_assault()
			self:_set_rescue_state(false)

			task_data.phase = "build"
			task_data.phase_end_t = self._t + self._tweak_data.assault.build_duration
			task_data.is_hesitating = nil

			self:set_assault_mode(true)
			managers.music:raid_music_state_change("assault")
			managers.trade:set_trade_countdown(false)
		else
			managers.hud:check_start_anticipation_music(task_data.phase_end_t - t)

			if task_data.is_hesitating and task_data.voice_delay < self._t then
				if self._hostage_headcount > 0 then
					local best_group = nil

					for _, group in pairs(self._groups) do
						if not best_group or group.objective.type == "reenforce_area" then
							best_group = group
						elseif best_group.objective.type ~= "reenforce_area" and group.objective.type ~= "retire" then
							best_group = group
						end
					end

					if best_group and self:_voice_delay_assault(best_group) then
						task_data.is_hesitating = nil
					end
				else
					task_data.is_hesitating = nil
				end
			end
		end
	elseif task_data.phase == "build" then
		if task_spawn_allowance <= 0 then
			task_data.phase = "fade"
			task_data.phase_end_t = t + self._tweak_data.assault.fade_duration
		elseif task_data.phase_end_t < t or self._drama_data.zone == "high" then
			task_data.phase = "sustain"
			task_data.phase_end_t = t + math.lerp(self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_min), self:get_difficulty_dependent_value(self._tweak_data.assault.sustain_duration_max), math.random()) * self:_get_balancing_multiplier(self._tweak_data.assault.sustain_duration_balance_mul)
		end
	elseif task_data.phase == "sustain" then
		if task_spawn_allowance <= 0 then
			task_data.phase = "fade"

			managers.music:raid_music_state_change("assault")

			task_data.phase_end_t = t + self._tweak_data.assault.fade_duration
		elseif task_data.phase_end_t < t and not self._hunt_mode then
			task_data.phase = "fade"
			task_data.phase_end_t = t + self._tweak_data.assault.fade_duration
		end
	else
		local end_assault = false
		local enemies_left = self:_count_police_force("assault")

		if not self._hunt_mode then
			self:_assign_assault_groups_to_retire()

			local min_enemies_left = 7

			if enemies_left < min_enemies_left or t > task_data.phase_end_t + 350 then
				if t > task_data.phase_end_t - 8 and not task_data.said_retreat then
					if self._drama_data.amount <= tweak_data.drama.assault_fade_end then
						task_data.said_retreat = true

						self:_police_announce_retreat(task_data)
					end
				elseif task_data.phase_end_t < t and self._drama_data.amount <= tweak_data.drama.assault_fade_end and self:_count_criminals_engaged_force(13) <= 12 then
					end_assault = true
				end
			else
				print("kill more enemies to end fade phase: ", min_enemies_left - enemies_left)
			end

			if task_data.force_end or end_assault then
				task_data.active = nil
				task_data.phase = nil
				task_data.said_retreat = nil

				if self._draw_drama then
					self._draw_drama.assault_hist[#self._draw_drama.assault_hist][2] = t
				end

				managers.music:raid_music_state_change("control")
				managers.mission:call_global_event("end_assault")
				self:_begin_regroup_task()

				return
			end
		else
			task_data.phase = "sustain"
			task_data.phase_end_t = t + 10
		end
	end

	if self._drama_data.amount <= tweak_data.drama.low then
		for criminal_key, criminal_data in pairs(self._player_criminals) do
			self:criminal_spotted(criminal_data.unit)

			for group_id, group in pairs(self._groups) do
				if group.objective.charge then
					for u_key, u_data in pairs(group.units) do
						u_data.unit:brain():clbk_group_member_attention_identified(nil, criminal_key)
					end
				end
			end
		end
	end

	local primary_target_area, target_pos = nil

	if task_data.target_areas then
		primary_target_area = task_data.target_areas[1]
		target_pos = primary_target_area.pos
	end

	if not primary_target_area or self:is_area_safe_assault(primary_target_area) then
		local nearest_area, nearest_dis = nil

		for criminal_key, criminal_data in pairs(self._player_criminals) do
			if not criminal_data.status then
				local dis = target_pos and mvector3.distance_sq(target_pos, criminal_data.m_pos) or 1000000

				if not nearest_dis or dis < nearest_dis then
					nearest_dis = dis
					nearest_area = self:get_area_from_nav_seg_id(criminal_data.tracker:nav_segment())
				end
			end
		end

		if nearest_area then
			primary_target_area = nearest_area
			task_data.target_areas = task_data.target_areas or {}
			task_data.target_areas[1] = nearest_area
		end
	end

	self:_upd_assault_spawning(task_data, primary_target_area)

	if task_data.phase ~= "anticipation" then
		if task_data.use_smoke_timer < t then
			task_data.use_smoke = true
		end

		if self._smoke_grenade_queued and task_data.use_smoke and not self:is_smoke_grenade_active() then
			self:detonate_smoke_grenade(self._smoke_grenade_queued[1], self._smoke_grenade_queued[1], self._smoke_grenade_queued[2], self._smoke_grenade_queued[4])

			if self._smoke_grenade_queued[3] then
				self._smoke_grenade_ignore_control = true
			end
		end
	end

	self:_assign_enemy_groups_to_assault(task_data.phase)
end

function GroupAIStateBesiege:_police_announce_retreat(task_data)
	local assault_pos = task_data.target_areas[1].pos

	local best_dis_sq, best_u_data

	for group_id, group in pairs(self._groups) do
		if group.objective.type == "assault_area" then
			local closest_u_id, closest_u_data, closest_u_dis_sq = self._get_closest_group_unit_to_pos(assault_pos, group.units)
			
			if not best_dis_sq or best_dis_sq > closest_u_dis_sq then
				best_dis_sq = closest_u_dis_sq
				best_u_data = closest_u_data
			end
			
			if best_dis_sq < 360000 then
				break
			end
		end
	end
	
	if best_u_data then
		if best_u_data.char_tweak.chatter.retreat then
			self:chk_say_enemy_chatter(best_u_data.unit, best_u_data.m_pos, "retreat")
		end
	end
end

function GroupAIStateBesiege:_set_assault_objective_to_group(group, phase)
	if not group.has_spawned then
		return
	end

	local phase_is_anticipation = phase == "anticipation"
	local current_objective = group.objective
	local approach, open_fire, push, pull_back, charge = nil
	local obstructed_area = self:_chk_group_areas_tresspassed(group)
	local group_leader_u_key, group_leader_u_data = self._determine_group_leader(group.units)
	local tactics_map = nil

	if group_leader_u_data and group_leader_u_data.tactics then
		tactics_map = {}

		for _, tactic_name in ipairs(group_leader_u_data.tactics) do
			tactics_map[tactic_name] = true
		end

		if current_objective.tactic and not tactics_map[current_objective.tactic] then
			current_objective.tactic = nil
		end

		for i_tactic, tactic_name in ipairs(group_leader_u_data.tactics) do
			if tactic_name == "deathguard" and not phase_is_anticipation then
				if current_objective.tactic == tactic_name then
					for u_key, u_data in pairs(self._char_criminals) do
						if u_data.status and current_objective.follow_unit == u_data.unit then
							local crim_nav_seg = u_data.tracker:nav_segment()

							if current_objective.area.nav_segs[crim_nav_seg] then
								return
							end
						end
					end
				end

				local closest_crim_u_data, closest_crim_dis_sq = nil

				for u_key, u_data in pairs(self._char_criminals) do
					if u_data.status then
						local closest_u_id, closest_u_data, closest_u_dis_sq = self._get_closest_group_unit_to_pos(u_data.m_pos, group.units)

						if closest_u_dis_sq and (not closest_crim_dis_sq or closest_u_dis_sq < closest_crim_dis_sq) then
							closest_crim_u_data = u_data
							closest_crim_dis_sq = closest_u_dis_sq
						end
					end
				end

				if closest_crim_u_data then
					local search_params = {
						id = "GroupAI_deathguard",
						from_tracker = group_leader_u_data.unit:movement():nav_tracker(),
						to_tracker = closest_crim_u_data.tracker,
						access_pos = self._get_group_acces_mask(group)
					}
					local coarse_path = managers.navigation:search_coarse(search_params)

					if coarse_path then
						local grp_objective = {
							distance = 800,
							type = "assault_area",
							attitude = "engage",
							tactic = "deathguard",
							moving_in = true,
							follow_unit = closest_crim_u_data.unit,
							area = self:get_area_from_nav_seg_id(coarse_path[#coarse_path][1]),
							coarse_path = coarse_path
						}
						group.is_chasing = true

						self:_set_objective_to_enemy_group(group, grp_objective)
						self:_voice_deathguard_start(group)

						return
					end
				end
			elseif tactic_name == "charge" and not current_objective.moving_out and group.in_place_t and (self._t - group.in_place_t > 15 or self._t - group.in_place_t > 4 and self._drama_data.amount <= tweak_data.drama.low) and next(current_objective.area.criminal.units) and group.is_chasing and not current_objective.charge then
				charge = true
			end
		end
	end

	local objective_area = nil

	if obstructed_area then
		if current_objective.moving_out then
			if not current_objective.open_fire then
				open_fire = true
			end
		elseif not current_objective.pushed or charge and not current_objective.charge then
			push = true
		end
	else
		local obstructed_path_index = self:_chk_coarse_path_obstructed(group)

		if obstructed_path_index then
			print("obstructed_path_index", obstructed_path_index)

			objective_area = self:get_area_from_nav_seg_id(group.coarse_path[math.max(obstructed_path_index - 1, 1)][1])
			pull_back = true
		elseif not current_objective.moving_out then
			local has_criminals_close = nil

			if not current_objective.moving_out then
				for area_id, neighbour_area in pairs(current_objective.area.neighbours) do
					if next(neighbour_area.criminal.units) then
						has_criminals_close = true

						break
					end
				end
			end

			if charge then
				push = true
			elseif not has_criminals_close or not group.in_place_t then
				approach = true
			elseif not phase_is_anticipation and not current_objective.open_fire then
				open_fire = true
			elseif not phase_is_anticipation and group.in_place_t and self._t - group.in_place_t > 2 then
				push = true
			elseif phase_is_anticipation and current_objective.open_fire then
				pull_back = true
			end
		end
	end

	objective_area = objective_area or current_objective.area

	if open_fire then
		local grp_objective = {
			attitude = "engage",
			type = "assault_area",
			stance = "hos",
			open_fire = true,
			tactic = current_objective.tactic,
			area = obstructed_area or current_objective.area,
			coarse_path = {
				{
					objective_area.pos_nav_seg,
					mvector3.copy(current_objective.area.pos)
				}
			}
		}

		self:_set_objective_to_enemy_group(group, grp_objective)
		self:_voice_open_fire_start(group)
	elseif approach or push then
		local assault_area, alternate_assault_area, alternate_assault_area_from, assault_path, alternate_assault_path = nil
		local to_search_areas = {
			objective_area
		}
		local found_areas = {
			[objective_area] = "init"
		}

		repeat
			local search_area = table.remove(to_search_areas, 1)

			if next(search_area.criminal.units) then
				local assault_from_here = true

				if not push and tactics_map and tactics_map.flank then
					local assault_from_area = found_areas[search_area]

					if assault_from_area ~= "init" then
						local cop_units = assault_from_area.police.units

						for u_key, u_data in pairs(cop_units) do
							if u_data.group and u_data.group ~= group and u_data.group.objective.type == "assault_area" then
								assault_from_here = false

								if not alternate_assault_area or math.random() < 0.5 then
									local search_params = {
										id = "GroupAI_assault",
										from_seg = current_objective.area.pos_nav_seg,
										to_seg = search_area.pos_nav_seg,
										access_pos = self._get_group_acces_mask(group),
										verify_clbk = callback(self, self, "is_nav_seg_safe")
									}
									alternate_assault_path = managers.navigation:search_coarse(search_params)

									if alternate_assault_path then
										self:_merge_coarse_path_by_area(alternate_assault_path)

										alternate_assault_area = search_area
										alternate_assault_area_from = assault_from_area
									end
								end

								found_areas[search_area] = nil

								break
							end
						end
					end
				end

				if assault_from_here then
					local search_params = {
						id = "GroupAI_assault",
						from_seg = current_objective.area.pos_nav_seg,
						to_seg = search_area.pos_nav_seg,
						access_pos = self._get_group_acces_mask(group),
						verify_clbk = callback(self, self, "is_nav_seg_safe")
					}
					assault_path = managers.navigation:search_coarse(search_params)

					if assault_path then
						self:_merge_coarse_path_by_area(assault_path)

						assault_area = search_area

						break
					end
				end
			else
				for other_area_id, other_area in pairs(search_area.neighbours) do
					if not found_areas[other_area] then
						table.insert(to_search_areas, other_area)

						found_areas[other_area] = search_area
					end
				end
			end
		until #to_search_areas == 0

		if not assault_area and alternate_assault_area then
			assault_area = alternate_assault_area
			found_areas[assault_area] = alternate_assault_area_from
			assault_path = alternate_assault_path
		end

		if assault_area and assault_path then
			local assault_area = push and assault_area or found_areas[assault_area] == "init" and objective_area or found_areas[assault_area]

			if #assault_path > 2 and assault_area.nav_segs[assault_path[#assault_path - 1][1]] then
				table.remove(assault_path)
			end

			local used_grenade = nil

			if push then
				local detonate_pos = nil

				if charge then
					for c_key, c_data in pairs(assault_area.criminal.units) do
						detonate_pos = c_data.unit:movement():m_pos()

						break
					end
				end

				local first_chk = math.random() < 0.5 and self._chk_group_use_flash_grenade or self._chk_group_use_smoke_grenade
				local second_chk = first_chk == self._chk_group_use_flash_grenade and self._chk_group_use_smoke_grenade or self._chk_group_use_flash_grenade
				used_grenade = first_chk(self, group, self._task_data.assault, detonate_pos)
				used_grenade = used_grenade or second_chk(self, group, self._task_data.assault, detonate_pos)

				self:_voice_move_in_start(group)
			end

			local grp_objective = {
				type = "assault_area",
				stance = "hos",
				area = assault_area,
				coarse_path = assault_path,
				attitude = phase_is_anticipation and "avoid" or "engage",
				moving_in = push and true or nil,
				open_fire = push or nil,
				pushed = push or nil,
				charge = charge,
				interrupt_dis = charge and 0 or nil
			}
			group.is_chasing = group.is_chasing or push

			self:_set_objective_to_enemy_group(group, grp_objective)
		end
	elseif pull_back then
		local retreat_area, do_not_retreat = nil

		for u_key, u_data in pairs(group.units) do
			local nav_seg_id = u_data.tracker:nav_segment()

			if current_objective.area.nav_segs[nav_seg_id] then
				retreat_area = current_objective.area

				break
			end

			if self:is_nav_seg_safe(nav_seg_id) then
				retreat_area = self:get_area_from_nav_seg_id(nav_seg_id)

				break
			end
		end

		if not retreat_area and not do_not_retreat and current_objective.coarse_path then
			local forwardmost_i_nav_point = self:_get_group_forwardmost_coarse_path_index(group)

			if forwardmost_i_nav_point then
				local nearest_safe_nav_seg_id = current_objective.coarse_path(forwardmost_i_nav_point)
				retreat_area = self:get_area_from_nav_seg_id(nearest_safe_nav_seg_id)
			end
		end

		if retreat_area then
			local new_grp_objective = {
				attitude = "avoid",
				stance = "hos",
				pose = "crouch",
				type = "assault_area",
				area = retreat_area,
				coarse_path = {
					{
						retreat_area.pos_nav_seg,
						mvector3.copy(retreat_area.pos)
					}
				}
			}
			group.is_chasing = nil

			self:_set_objective_to_enemy_group(group, new_grp_objective)

			return
		end
	end
end

function GroupAIStateBesiege:_count_criminals_engaged_force(max_count)
	local count = 0
	local all_enemies = self._police
	local mvec3_dis_sq = mvector3.distance_sq
	local char_criminals = self._char_criminals

	for c_key, c_data in pairs(self._char_criminals) do
		local c_unit = c_data.unit
		
		if alive(c_unit) then
			if c_unit:movement()._attackers then
				local criminal_pos = c_unit:movement():m_pos()
				local cops_attacking_criminal = c_unit:movement()._attackers
			
				for e_key, cop_unit in pairs(cops_attacking_criminal) do
					local e_data = all_enemies[e_key]

					if alive(cop_unit) and e_data then
						local brain = cop_unit:brain()
						local objective = brain:objective()
						
						if brain._logic_data and brain._logic_data.internal_data and brain._logic_data.internal_data.attitude == "engage" then
							local cop_pos = cop_unit:movement():m_pos()

							if mvec3_dis_sq(cop_pos, criminal_pos) < 4000000 then
								count = count + 1

								if max_count and count == max_count then
									return count
								end
							end
						end
					end
				end
			end
		end
	end
	

	return count
end

function GroupAIStateBesiege._create_objective_from_group_objective(grp_objective, receiving_unit)
	local objective = {
		grp_objective = grp_objective
	}

	if grp_objective.element then
		objective = grp_objective.element:get_random_SO(receiving_unit)

		if not objective then
			return
		end

		objective.grp_objective = grp_objective

		return
	elseif grp_objective.type == "defend_area" or grp_objective.type == "recon_area" or grp_objective.type == "reenforce_area" then
		objective.type = "defend_area"
		objective.stance = "hos"
		objective.pose = "crouch"
		objective.scan = true
		objective.interrupt_dis = 200
		objective.interrupt_suppression = true
	elseif grp_objective.type == "retire" then
		objective.type = "defend_area"
		objective.stance = "hos"
		objective.pose = "stand"
		objective.scan = true
		objective.interrupt_dis = 200
		objective.action = grp_objective.action
	elseif grp_objective.type == "assault_area" then
		objective.type = "defend_area"

		if grp_objective.follow_unit then
			objective.follow_unit = grp_objective.follow_unit
			objective.distance = grp_objective.distance
		end

		objective.stance = "hos"
		objective.pose = "stand"
		objective.scan = true
		objective.interrupt_dis = 200
		objective.interrupt_suppression = true
	elseif grp_objective.type == "create_phalanx" then
		objective.type = "phalanx"
		objective.stance = "hos"
		objective.interrupt_dis = nil
		objective.interrupt_health = nil
		objective.interrupt_suppression = nil
		objective.attitude = "avoid"
		objective.path_ahead = true
	elseif grp_objective.type == "hunt" then
		objective.type = "hunt"
		objective.stance = "hos"
		objective.scan = true
		objective.interrupt_dis = 200
	end
	
	if objective.type == "defend_area" and not objective.action then
		objective.interrupt_on_contact = true
	end

	objective.stance = grp_objective.stance or objective.stance
	objective.pose = grp_objective.pose or objective.pose
	objective.area = grp_objective.area
	objective.nav_seg = grp_objective.nav_seg or objective.area.pos_nav_seg
	objective.attitude = grp_objective.attitude or objective.attitude
	objective.interrupt_dis = grp_objective.interrupt_dis or objective.interrupt_dis
	objective.interrupt_health = grp_objective.interrupt_health or objective.interrupt_health
	objective.interrupt_suppression = grp_objective.interrupt_suppression or objective.interrupt_suppression
	objective.pos = grp_objective.pos

	if grp_objective.scan ~= nil then
		objective.scan = grp_objective.scan
	end

	if grp_objective.coarse_path then
		objective.path_style = "coarse_complete"
		objective.path_data = grp_objective.coarse_path
	end

	return objective
end

function GroupAIStateBesiege:_choose_best_group(best_groups, total_weight)
	local rand_wgt = total_weight * math.random()
	local best_grp, best_grp_nationality, best_grp_type = nil

	for i, candidate in ipairs(best_groups) do
		rand_wgt = rand_wgt - candidate.wght

		if rand_wgt <= 0 then
			best_grp = candidate.group
			best_grp_nationality = candidate.nationality
			best_grp_type = candidate.group_type
			best_grp.delay_t = self._t + best_grp.interval

			break
		end
	end
	
	if best_grp_type == "commander_squad" then
		self:waypoint_random_commander()
	end

	return best_grp, best_grp_nationality, best_grp_type
end

function GroupAIStateBesiege:waypoint_random_commander()	
	if not Network:is_server() then
		return
	end
		
	if self._special_units.commander then
		local u_key = nil
		
		for r_u_key, _ in pairs(self._special_units.commander) do
			u_key = r_u_key
			
			break
		end
		
		local all_enemies = self._police
		
		if u_key and all_enemies[u_key] then
			local u_data = all_enemies[u_key]
			
			if u_data and u_data.unit and alive(u_data.unit) then
				local waypoint_id = "commander_call_pos" .. tostring(u_key)
				
				if not managers.hud._hud or not managers.hud._hud.waypoints[waypoint_id] then
					local waypoint_data = {
						present_timer = 0,
						position = u_data.unit:movement():m_head_pos(),
						distance = true,
						radius = 160,
						icon = "wp_calling_in",
						no_sync = true,
						waypoint_type = "unit_waypoint",
						color = Color("de4a3e")
					}
						
					managers.hud:add_waypoint(waypoint_id, waypoint_data)
				end
				
				local function rem_waypoint()
					managers.hud:remove_waypoint(waypoint_id)
				end
				
				local clbk_id = "remove_commander_waypoint" .. tostring(u_key)
				
				managers.enemy:safe_schedule_clbk(clbk_id, rem_waypoint, self._t + 6)
				
				--sync to clients through event id stuff
				managers.network:session():send_to_peers_synched("sync_unit_event_id_16", u_data.unit, "brain", HuskCopBrain._NET_EVENTS.officer_waypoint)
			end
		end
	end
end