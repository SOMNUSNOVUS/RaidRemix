local mvec3_set = mvector3.set
local mvec3_sub = mvector3.subtract
local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local t_rem = table.remove
local t_ins = table.insert
local m_min = math.min
local tmp_vec1 = Vector3()

function EnemyManager:is_spawn_group_allowed(group_type)
	local allowed = true

	if not managers.enemy:is_commander_active() and group_type == "commander_squad" then
		allowed = false
	end

	return allowed
end

function EnemyManager:safe_schedule_clbk(id, clbk, execute_t)
	local all_clbks = self._delayed_clbks
	local clbk_data = nil

	for i, clbk_d in ipairs(all_clbks) do
		if clbk_d[1] == id then
			clbk_data = table.remove(all_clbks, i)

			break
		end
	end

	if clbk_data then
		clbk_data[2] = execute_t
		local i = #all_clbks

		while i > 0 and execute_t < all_clbks[i][2] do
			i = i - 1
		end

		table.insert(all_clbks, i + 1, clbk_data)

		return
	elseif clbk ~= nil then
		self:add_delayed_clbk(id, clbk, execute_t)
	end
end