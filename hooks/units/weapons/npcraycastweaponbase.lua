local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_dot = mvector3.dot
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_dir = mvector3.direction
local mvec3_set_l = mvector3.set_length
local mvec3_len = mvector3.length
local math_clamp = math.clamp
local math_lerp = math.lerp
local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_rot1 = Rotation()

local mvec_to = Vector3()

function NPCRaycastWeaponBase:_fire_raycast(user_unit, from_pos, direction, dmg_mul, shoot_player, target_unit)
	local enemy_type = ""
	local char_tweak = user_unit and user_unit:base() and user_unit:base()._tweak_table and tweak_data.character[user_unit:base()._tweak_table]
	
	if char_tweak then
		enemy_type = char_tweak.type
	end

	local character_data = managers.criminals:character_data_by_unit(user_unit)
	local is_team_ai = character_data ~= nil

	if not is_team_ai and managers.buff_effect:is_effect_active(BuffEffectManager.EFFECT_ENEMY_DOES_DAMAGE) then
		local effect_value_enemy_damage_modifier = managers.buff_effect:get_effect_value(BuffEffectManager.EFFECT_ENEMY_DOES_DAMAGE)
		dmg_mul = dmg_mul * effect_value_enemy_damage_modifier
	end

	local usage = self:weapon_tweak_data().usage
	local range = 20000
	
	if char_tweak and usage then
		if char_tweak.weapon then
			if char_tweak.weapon[usage].max_range then
				range = char_tweak.weapon[usage].max_range
			end
		end
	end

	local result = {}
	local hit_unit = nil

	mvector3.set(mvec_to, direction)
	mvector3.multiply(mvec_to, range)
	mvector3.add(mvec_to, from_pos)

	local damage = self._damage * (dmg_mul or 1)
	local col_ray = World:raycast("ray", from_pos, mvec_to, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units)
	local bullet_class = self._bullet_class or InstantBulletBase
	local player_hit, player_ray_data = nil

	if shoot_player and self._hit_player then
		player_hit, player_ray_data = self:damage_player(col_ray, from_pos, direction, range)

		if player_hit then
			bullet_class:on_hit_player(col_ray or player_ray_data, self._unit, user_unit, damage)
		end
	end

	local char_hit = nil

	if not player_hit and col_ray then
		char_hit = bullet_class:on_collision(col_ray, self._unit, user_unit, damage)
	end
	
	if not shoot_player then
		if (not col_ray or col_ray.unit ~= target_unit) and target_unit and target_unit:character_damage() and target_unit:character_damage().build_suppression then
			target_unit:character_damage():build_suppression(tweak_data.weapon[self._name_id].suppression)
		end
	end

	if not col_ray or col_ray.distance > 600 then
		self:_spawn_trail_effect(direction, col_ray)
	end

	result.hit_enemy = char_hit

	if self._alert_events then
		result.rays = {
			col_ray
		}
	end

	return result
end

function NPCRaycastWeaponBase:damage_player(col_ray, from_pos, direction, range)
	local unit = managers.player:player_unit()

	if not unit then
		return
	end

	local ray_data = {
		ray = direction,
		normal = -direction
	}
	local head_pos = unit:movement():m_head_pos()
	local head_dir = tmp_vec1
	local head_dis = mvec3_dir(head_dir, from_pos, head_pos)
	
	if range < head_dis then
		return
	end
	
	local shoot_dir = tmp_vec2

	mvec3_set(shoot_dir, col_ray and col_ray.ray or direction)

	local cos_f = mvec3_dot(shoot_dir, head_dir)

	if cos_f <= 0.1 then
		return
	end

	local b = head_dis / cos_f

	if not col_ray or b < col_ray.distance then
		if col_ray and b - col_ray.distance < 60 then
			unit:character_damage():build_suppression(self._suppression)
		end

		mvec3_set_l(shoot_dir, b)
		mvec3_mul(head_dir, head_dis)
		mvec3_sub(shoot_dir, head_dir)

		local proj_len = mvec3_len(shoot_dir)
		ray_data.position = head_pos + shoot_dir

		if not col_ray and proj_len < 60 then
			unit:character_damage():build_suppression(self._suppression)
		end

		if proj_len < 30 then
			if World:raycast("ray", from_pos, head_pos, "slot_mask", self._bullet_slotmask, "ignore_unit", self._setup.ignore_units, "report") then
				return nil, ray_data
			else
				return true, ray_data
			end
		elseif proj_len < 100 and b > 500 and (not self.weapon_tweak_data or not self:weapon_tweak_data().no_whizby) then
			unit:character_damage():play_whizby(ray_data.position, self._unit:base().sentry_gun)
		end
	elseif b - col_ray.distance < 60 then
		unit:character_damage():build_suppression(self._suppression)
	end

	return nil, ray_data
end
