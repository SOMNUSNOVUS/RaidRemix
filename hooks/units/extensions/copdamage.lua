function CopDamage:_AI_comment_death(unit, type)
	if type == "tank" then
		-- Nothing
	elseif type == "taser" then
		-- Nothing
	elseif type == "shield" then
		-- Nothing
	elseif type == "sniper" or type == "german_sniper" then
		managers.dialog:queue_dialog("enemy_sniper_comment_death", {
			skip_idle_check = true,
			instigator = unit
		})
	elseif type == "german_flamer" then
		managers.dialog:queue_dialog("enemy_flamer_comment_death", {
			skip_idle_check = true,
			instigator = unit
		})
	elseif type == "german_officer" or type == "german_commander" or type == "german_og_commander" then
		managers.dialog:queue_dialog("enemy_officer_comment_death", {
			skip_idle_check = true,
			instigator = unit
		})
	elseif type == "german_spotter" then
		managers.dialog:queue_dialog("enemy_spotter_comment_death", {
			skip_idle_check = true,
			instigator = unit
		})
	end
end