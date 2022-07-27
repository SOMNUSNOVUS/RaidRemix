function CopBrain:search_for_path(search_id, to_pos, prio, access_neg, nav_segs)
	if not prio then
		prio = CopLogicTravel.get_pathing_prio(self._logic_data)
	end

	local params = {
		tracker_from = self._unit:movement():nav_tracker(),
		pos_to = to_pos,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		prio = prio,
		access_pos = self._SO_access,
		access_neg = access_neg,
		nav_segs = nav_segs
	}
	
	self._logic_data.active_searches[search_id] = true

	managers.navigation:search_pos_to_pos(params)

	return true
end

function CopBrain:search_for_path_from_pos(search_id, from_pos, to_pos, prio, access_neg, nav_segs)
	if not prio then
		prio = CopLogicTravel.get_pathing_prio(self._logic_data)
	end

	local params = {
		pos_from = from_pos,
		pos_to = to_pos,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		prio = prio,
		access_pos = self._SO_access,
		access_neg = access_neg,
		nav_segs = nav_segs
	}
	
	self._logic_data.active_searches[search_id] = true

	managers.navigation:search_pos_to_pos(params)

	return true
end

function CopBrain:search_for_path_to_cover(search_id, cover, offset_pos, access_neg)
	local prio = CopLogicTravel.get_pathing_prio(self._logic_data)

	local params = {
		tracker_from = self._unit:movement():nav_tracker(),
		tracker_to = cover[3],
		prio = prio,
		result_clbk = callback(self, self, "clbk_pathing_results", search_id),
		id = search_id,
		access_pos = self._SO_access,
		access_neg = access_neg
	}
	
	if offset_pos then
		params.pos_to = offset_pos
		params.tracker_to = nil
	end
	
	self._logic_data.active_searches[search_id] = true
	managers.navigation:search_pos_to_pos(params)

	return true
end

Hooks:PostHook(CopBrain, "_add_pathing_result", "lies_pathing", function(self, search_id, path)
	if path and path ~= "failed" then
		--enemies in logictravel and logicattack will perform their appropriate actions as soon as possible once pathing has finished
		
		if self._current_logic._pathing_complete_clbk then
			self._logic_data.t = self._timer:time()
			self._logic_data.dt = self._timer:delta_time()
		
			self._current_logic._pathing_complete_clbk(self._logic_data)
		end
	end
end)

Hooks:PostHook(CopBrain, "clbk_death", "raid_clbk_death", function(self, my_unit, damage_info)
	local u_key = my_unit:key()
	local waypoint_id = "commander_call_pos" .. tostring(u_key)
	
	managers.hud:remove_waypoint(waypoint_id)
	
	if self.is_flamer then
		self._unit:sound_source():post_event("flamer_breathing_break")
		
		if self._flamer_effect then
			World:effect_manager():fade_kill(self._flamer_effect)
			self._flamer_effect = nil
			self._flamer_effect_table = nil
		end
	end
end)

Hooks:PostHook(CopBrain, "pre_destroy", "raid_pre_destroy", function(self)
	local u_key = self._unit:key()
	local waypoint_id = "commander_call_pos" .. tostring(u_key)
	
	managers.hud:remove_waypoint(waypoint_id)
	
	if self.is_flamer then
		self._unit:sound_source():post_event("flamer_breathing_break")
		
		if self._flamer_effect then
			World:effect_manager():fade_kill(self._flamer_effect)
			self._flamer_effect = nil
			self._flamer_effect_table = nil
		end
	end
end)