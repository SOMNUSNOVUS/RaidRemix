function CopLogicIdle._upd_enemy_detection(data)
	if data.unit:brain().dead then
		return
	end

	managers.groupai:state():on_unit_detection_updated(data.unit)

	data.t = TimerManager:game():time()
	local my_data = data.internal_data
	local min_reaction = not data.cool and AIAttentionObject.REACT_SCARED
	local delay = CopLogicBase._upd_attention_obj_detection(data, min_reaction, nil)
	local new_attention, new_prio_slot, new_reaction = CopLogicBase._get_priority_attention(data, data.detected_attention_objects)

	CopLogicBase._set_attention_obj(data, new_attention, new_reaction)

	if new_reaction and AIAttentionObject.REACT_SUSPICIOUS < new_reaction then
		local objective = data.objective
		local wanted_logic = nil
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, new_attention)

		if allow_trans then
			wanted_logic = CopLogicBase._get_logic_state_from_reaction(data)
		end

		if wanted_logic and wanted_logic ~= data.name then
			if obj_failed then
				data.objective_failed_clbk(data.unit, data.objective)
			end

			if my_data == data.internal_data and not data.unit:brain().logic_queued_key then
				local params = nil

				if managers.groupai:state():whisper_mode() and my_data.vision.detection_delay then
					params = {
						delay = my_data.vision.detection_delay
					}
				end

				CopLogicBase._exit(data.unit, wanted_logic, params)
			end
		end
	end

	if my_data == data.internal_data then
		CopLogicBase._chk_call_the_police(data)

		if my_data ~= data.internal_data then
			return delay
		end
	end

	return delay
end