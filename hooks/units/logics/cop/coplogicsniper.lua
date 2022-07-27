function CopLogicSniper._upd_aim_action(data, my_data)
	local focus_enemy = data.attention_obj
	local action_taken = nil
	local anim_data = data.unit:anim_data()

	if anim_data.reload and not anim_data.crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
		action_taken = CopLogicAttack._request_action_crouch(data)
	end

	if action_taken then
		-- Nothing
	elseif not data.is_suppressed then
		if focus_enemy then
			if not CopLogicAttack._request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.verified_pos or focus_enemy.m_head_pos) and not focus_enemy.verified and not anim_data.reload then
				if anim_data.crouch then
					if (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.stand) and not CopLogicSniper._chk_stand_visibility(data.m_pos, focus_enemy.m_head_pos, data.visibility_slotmask) then
						CopLogicAttack._request_action_stand(data)
					end
				elseif (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) and not CopLogicSniper._chk_crouch_visibility(data.m_pos, focus_enemy.m_head_pos, data.visibility_slotmask) then
					CopLogicAttack._request_action_crouch(data)
				end
			end
		elseif my_data.wanted_pose and not anim_data.reload then
			if my_data.wanted_pose == "crouch" then
				if not anim_data.crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
					action_taken = CopLogicAttack._request_action_crouch(data)
				end
			elseif not anim_data.stand and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.stand) then
				action_taken = CopLogicAttack._request_action_stand(data)
			end
		end
	elseif focus_enemy then
		if not CopLogicAttack._request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.verified_pos or focus_enemy.m_head_pos) and focus_enemy.verified and anim_data.stand and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) and CopLogicSniper._chk_crouch_visibility(data.m_pos, focus_enemy.m_head_pos, data.visibility_slotmask) then
			CopLogicAttack._request_action_crouch(data)
		end
	elseif my_data.wanted_pose and not anim_data.reload then
		if my_data.wanted_pose == "crouch" then
			if not anim_data.crouch and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch) then
				action_taken = CopLogicAttack._request_action_crouch(data)
			end
		elseif not anim_data.stand and (not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.stand) then
			action_taken = CopLogicAttack._request_action_stand(data)
		end
	end

	return action_taken
end