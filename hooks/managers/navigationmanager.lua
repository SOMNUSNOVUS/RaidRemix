local mvec3_rot = mvector3.rotate_with
local mvec3_cpy = mvector3.copy
local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_dir = mvector3.direction
local mvec3_mul = mvector3.multiply

local temp_vec1 = Vector3()

function NavigationManager:find_cover_in_cone_from_threat_pos(threat_pos, cone_base, near_pos, cone_angle, nav_seg, rsrv_filter)
	if type(nav_seg) == "table" then
		nav_seg = self._convert_nav_seg_map_to_vec(nav_seg)
	end

	local search_params = {
		variation_z = 250,
		near_pos = near_pos,
		threat_pos = threat_pos,
		cone_angle = cone_angle,
		cone_base = cone_base,
		in_nav_seg = nav_seg,
		rsrv_filter = rsrv_filter
	}
	local t = TimerManager:now()
	local ret = nil

	if nav_seg then
		ret = self._quad_field:find_cover(search_params)
	else
		ret = self._quad_field:find_cover_in_cone(near_pos, threat_pos, cone_angle, cone_base, rsrv_filter)
	end

	return ret
end

function NavigationManager:pad_out_position(position, nr_rays, dis)
	nr_rays = math.max(2, nr_rays or 4)
	dis = dis or 46.5
	local angle = 360
	local rot_step = angle / nr_rays
	local rot_offset = 1 * angle * 0.5
	local ray_rot = Rotation(-angle * 0.5 + rot_offset - rot_step)
	local vec_to = Vector3(dis, 0, 0)

	mvec3_rot(vec_to, ray_rot)

	local pos_to = Vector3()

	mrotation.set_yaw_pitch_roll(ray_rot, rot_step, 0, 0)

	local ray_params = {
		allow_entry = true,
		trace = true,
		pos_from = position,
		pos_to = pos_to
	}
	local ray_results = {}
	local i_ray = 1
	local tmp_vec = temp_vec1
	local altered_pos = mvec3_cpy(position)
	
	while nr_rays >= i_ray do
		mvec3_rot(vec_to, ray_rot)
		mvec3_set(pos_to, vec_to)
		mvec3_add(pos_to, altered_pos)
		local hit = self:raycast(ray_params)

		if hit then
			mvec3_dir(tmp_vec, ray_params.trace[1], position)
			mvec3_mul(tmp_vec, dis)
			mvec3_add(altered_pos, tmp_vec)
		end

		i_ray = i_ray + 1
	end
	
	local position_tracker = self._quad_field:create_nav_tracker(altered_pos, true)
	altered_pos = mvec3_cpy(position_tracker:field_position())

	self._quad_field:destroy_nav_tracker(position_tracker)
	
	return altered_pos
end