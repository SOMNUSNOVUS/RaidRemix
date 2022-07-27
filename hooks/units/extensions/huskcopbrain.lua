function HuskCopBrain:init(unit)
	self._unit = unit
	
	if self.is_flamer then
		self._unit:sound_source():post_event("flamer_breathing_start")
		
		self._flamer_effect_table = {
			effect = Idstring("effects/vanilla/character/flamer_eyes"),
			parent = self._unit:get_object(Idstring("Head"))
		}
		
		self._flamer_effect = World:effect_manager():spawn(self._flamer_effect_table)
	end
end

HuskCopBrain._NET_EVENTS = {
	officer_waypoint = 3,
	weapon_laser_off = 2,
	weapon_laser_on = 1
}

function HuskCopBrain:sync_net_event(event_id)
	if event_id == self._NET_EVENTS.weapon_laser_on then
		self._weapon_laser_on = true

		self._unit:inventory():equipped_unit():base():set_laser_enabled(true)
		managers.enemy:_destroy_unit_gfx_lod_data(self._unit:key())
	elseif event_id == self._NET_EVENTS.weapon_laser_off then
		self._weapon_laser_on = nil

		if self._unit:inventory():equipped_unit() then
			self._unit:inventory():equipped_unit():base():set_laser_enabled(false)
		end

		if not self._unit:character_damage():dead() then
			managers.enemy:_create_unit_gfx_lod_data(self._unit)
		end
	elseif event_id == self._NET_EVENTS.officer_waypoint then
		if self._unit and alive(self._unit) then
			local u_key = self._unit:key()
			local waypoint_id = "commander_call_pos" .. tostring(u_key)
			
			if not managers.hud._hud or not managers.hud._hud.waypoints[waypoint_id] then
				local waypoint_data = {
					present_timer = 0,
					position = self._unit:movement():m_head_pos(),
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
				
			managers.enemy:safe_schedule_clbk(clbk_id, rem_waypoint, TimerManager:game():time() + 10)
		end
	end
end

Hooks:PostHook(HuskCopBrain, "pre_destroy", "raid_pre_destroy", function(self)
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