local tmp_vec1 = Vector3()

function TeamAILogicIdle._check_should_relocate(data, my_data, objective)
	if data.cool or data.unit:movement()._should_stay then
		return
	end

	local follow_unit = objective.follow_unit

	local max_allowed_dis_xy = 700
	local max_allowed_dis_z = 250

	mvector3.set(tmp_vec1, follow_unit:movement():m_pos())
	mvector3.subtract(tmp_vec1, data.m_pos)

	local too_far = nil

	if max_allowed_dis_z < math.abs(mvector3.z(tmp_vec1)) then
		too_far = true
	else
		mvector3.set_z(tmp_vec1, 0)

		if max_allowed_dis_xy < mvector3.length(tmp_vec1) then
			too_far = true
		end
	end

	if too_far then
		return true
	end
end

function TeamAILogicIdle._get_priority_attention(data, attention_objects, reaction_func)
	reaction_func = reaction_func or TeamAILogicBase._chk_reaction_to_attention_object
	local best_target, best_target_priority_slot, best_target_priority, best_target_reaction = nil
	
	local ranges = data.internal_data and data.internal_data.weapon_range
	
	if not ranges then
		ranges = {
			optimal = 2000,
			far = 5000,
			close = 1000
		}
	end

	for u_key, attention_data in pairs(attention_objects) do
		local att_unit = attention_data.unit
		local crim_record = attention_data.criminal_record

		if not attention_data.identified then
			-- Nothing
		elseif attention_data.pause_expire_t then
			if attention_data.pause_expire_t < data.t then
				attention_data.pause_expire_t = nil
			end
		elseif attention_data.stare_expire_t and attention_data.stare_expire_t < data.t then
			if attention_data.settings.pause then
				attention_data.stare_expire_t = nil
				attention_data.pause_expire_t = data.t + math.lerp(attention_data.settings.pause[1], attention_data.settings.pause[2], math.random())
			end
		else
			local distance = mvector3.distance(data.m_pos, attention_data.m_pos)
			local reaction = reaction_func(data, attention_data, not CopLogicAttack._can_move(data))
			local reaction_too_mild = nil

			if not reaction or best_target_reaction and reaction < best_target_reaction then
				reaction_too_mild = true
			elseif distance < 150 and reaction <= AIAttentionObject.REACT_SURPRISED then
				reaction_too_mild = true
			end

			if not reaction_too_mild then
				local aimed_at = TeamAILogicIdle.chk_am_i_aimed_at(data, attention_data, attention_data.aimed_at and 0.95 or 0.985)
				attention_data.aimed_at = aimed_at
			
				local alert_dt = attention_data.alert_t and data.t - attention_data.alert_t or 10000
				local dmg_dt = attention_data.dmg_t and data.t - attention_data.dmg_t or 10000
				local mark_dt = attention_data.mark_t and data.t - attention_data.mark_t or 10000
				local target_priority = distance
				local close_threshold = ranges.close

				if data.attention_obj and data.attention_obj.u_key == u_key then
					alert_dt = alert_dt * 0.8
					dmg_dt = dmg_dt * 0.8
					mark_dt = mark_dt * 0.8
					distance = distance * 0.8
					target_priority = target_priority * 0.8
				end

				local visible = attention_data.verified
				
				local target_priority_slot = 0

				if visible then
					local is_shielded = TeamAILogicIdle._ignore_shield and TeamAILogicIdle._ignore_shield(data.unit, attention_data) or nil
					
					if is_shielded then
						target_priority_slot = 10
					else
						local near = distance < close_threshold
						local has_alerted = alert_dt < 5
						local has_damaged = dmg_dt < 2
						local been_marked = mark_dt < 8
						local attention_unit = attention_data.unit
						
						if attention_unit:base().sentry_gun or attention_unit:base()._tweak_table and attention_unit:base()._tweak_table == "german_spotter" then
							if near and (has_alerted and has_damaged) then
								target_priority_slot = 7
							elseif near then
								target_priority_slot = 8
							else
								target_priority_slot = 9
							end
						elseif attention_unit:base()._tweak_table then
							if attention_unit:base()._tweak_table == "german_sniper" and aimed_at then
								if has_damaged then
									target_priority_slot = 2
								elseif has_alerted then
									target_priority_slot = 4
								else
									target_priority_slot = 7
								end
							elseif attention_unit:base()._tweak_table == "german_flamer" then
								if distance < 1500 then
									target_priority_slot = 2 
								elseif near then
									target_priority_slot = 3
								else
									target_priority_slot = 6
								end
							elseif attention_unit:base()._tweak_table == "german_commander" or attention_unit:base()._tweak_table == "german_og_commander" then
								if near and (has_alerted and has_damaged) then
									target_priority_slot = 2
								elseif near then
									target_priority_slot = 3
								else
									target_priority_slot = 6
								end
							elseif near and (has_alerted and has_damaged) then
								target_priority_slot = 7
							elseif near then
								target_priority_slot = 8
							else
								target_priority_slot = 9
							end
						elseif near and (has_alerted and has_damaged) then
							target_priority_slot = 8
						elseif near then
							target_priority_slot = 9
						else
							target_priority_slot = 10
						end
					end
				else
					target_priority_slot = 11
				end

				if reaction < AIAttentionObject.REACT_COMBAT then
					target_priority = target_priority * 10
					target_priority_slot = 11 + target_priority_slot + math.max(0, AIAttentionObject.REACT_COMBAT - reaction)
				end

				if target_priority_slot ~= 0 then
					local best = false

					if not best_target then
						best = true
					elseif target_priority_slot < best_target_priority_slot then
						best = true
					elseif target_priority_slot == best_target_priority_slot and target_priority < best_target_priority then
						best = true
					end

					if best then
						best_target = attention_data
						best_target_priority_slot = target_priority_slot
						best_target_priority = target_priority
						best_target_reaction = reaction
					end
				end
			end
		end
	end

	return best_target, best_target_priority_slot, best_target_reaction
end

function TeamAILogicIdle.update(data)
	TeamAILogicTravel._upd_ai_perceptors(data)

	local my_data = data.internal_data

	CopLogicIdle._upd_pathing(data, my_data)
	CopLogicIdle._upd_scan(data, my_data)

	local objective = data.objective

	if objective and objective.type ~= "free" then
		if not my_data.acting then
			if objective.type == "follow" then
				if TeamAILogicIdle._check_should_relocate(data, my_data, objective) and not data.unit:movement():chk_action_forbidden("walk") then
					objective.in_place = nil

					TeamAILogicBase._exit(data.unit, "travel")
				end
			elseif objective.type == "revive" then
				objective.in_place = nil

				TeamAILogicBase._exit(data.unit, "travel")
			end
		end
	elseif not data.path_fail_t or data.t - data.path_fail_t > 2 then
		managers.groupai:state():on_criminal_jobless(data.unit)
	end
end