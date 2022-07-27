Hooks:PostHook(CopMovement, "post_init", "raid_post_init", function(self)
	if Network:is_server() then
		if alive(self._unit) then
			if self._ext_base._tweak_table == "german_flamer" then
				local my_unit = self._unit
			
				local function f()
					if alive(my_unit) then
						if my_unit:spawn_manager() then
							my_unit:spawn_manager():run_flamer_staticize()
						end
					end
				end
				
				managers.enemy:add_delayed_clbk("flamer_statics_enable" .. tostring(my_unit:key()), f, TimerManager:game():time())
			end
		end
	end
end)