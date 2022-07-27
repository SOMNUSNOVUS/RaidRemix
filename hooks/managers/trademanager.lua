function TradeManager:on_AI_criminal_death(criminal_name, respawn_penalty, hostages_killed, skip_netsend)
	--print("[TradeManager:on_AI_criminal_death]", criminal_name, respawn_penalty, hostages_killed, skip_netsend)

	local criminal_unit = managers.criminals:character_unit_by_name(criminal_name)
	
	if managers.hud then 
		if alive(criminal_unit) then
			local teammate_panel_id = criminal_unit:unit_data() and criminal_unit:unit_data().teammate_panel_id
			local name_label_id = criminal_unit:unit_data() and criminal_unit:unit_data().name_label_id

			managers.hud:on_teammate_died(teammate_panel_id, name_label_id)
		end
	end
	
	if tweak_data.player.damage.automatic_respawn_time then
		respawn_penalty = math.min(respawn_penalty, tweak_data.player.damage.automatic_respawn_time)
	end

	local crim = {
		ai = true,
		id = criminal_name,
		respawn_penalty = respawn_penalty,
		hostages_killed = hostages_killed
	}

	local inserted = false

	for i, crim_to_respawn in ipairs(self._criminals_to_respawn) do
		if crim_to_respawn.ai or respawn_penalty < crim_to_respawn.respawn_penalty then
			table.insert(self._criminals_to_respawn, i, crim)

			inserted = true

			break
		end
	end

	if not inserted then
		table.insert(self._criminals_to_respawn, crim)
	end

	if Network:is_server() and not skip_netsend then
		managers.network:session():send_to_peers_synched("set_trade_death", criminal_name, respawn_penalty, hostages_killed)
		self:sync_set_trade_death(criminal_name, respawn_penalty, hostages_killed, true)
	end

	return crim
end

function TradeManager:update_auto_assault_ai_trade(dt, is_trade_allowed)
	if self._auto_assault_ai_trade_t then
		self._auto_assault_ai_trade_t = self._auto_assault_ai_trade_t - dt
	end

	if not Network:is_server() then
		return false
	end

	if not is_trade_allowed or self._trade_countdown or not managers.groupai:state():is_ai_trade_possible() then
		if not self:is_trading() then
			self:_set_auto_assault_ai_trade(nil, 0)
		end

		return false
	end

	local min_crim = self:get_min_criminal_to_trade()

	if not min_crim then
		Application:error("AI trade possible even though no one to trade.\n", inspect(self._criminals_to_respawn))

		return false
	end

	if not self._auto_assault_ai_trade_t then
		self._auto_assault_ai_trade_t = tweak_data.player.damage.automatic_respawn_time
	end

	local time = self._auto_assault_ai_trade_t + math.max(0, min_crim.respawn_penalty)
	time = math.min(time, tweak_data.player.damage.automatic_assault_ai_trade_time_max)

	self:_set_auto_assault_ai_trade(min_crim.id, time)

	return time <= self.TRADE_DELAY
end

function TradeManager:get_min_criminal_to_trade()
	local min_crim = nil

	for _, crim in ipairs(self._criminals_to_respawn) do
		if not min_crim or crim.respawn_penalty < min_crim.respawn_penalty then
			min_crim = crim
		end
	end

	return min_crim
end

function TradeManager:get_criminal_to_trade(wait_for_player)
	local ai_crim, has_player = nil

	for _, crim in ipairs(self._criminals_to_respawn) do
		has_player = has_player or not crim.ai

		if crim.respawn_penalty <= 0 then
			if not crim.ai then
				return crim
			else
				ai_crim = ai_crim or crim
			end
		end
	end

	return ai_crim
end