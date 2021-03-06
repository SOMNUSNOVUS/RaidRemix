Hooks:PostHook(GuiTweakData, "_setup_hud_colors", "_setup_hud_colors__rex", function(self)
	-- efad29 is old interaction/teammate overhead name/etc.
	-- fe0000 OR c20015, one is likely the old HP color (no info on low HP from E3)
	-- f38212 is the current color to near-empty ammo (not accurate yet)
	
	self.colors.ammo_background_outline = Color("0c0c0d")
	self.colors.ammo_text = Color("222222")
	self.colors.warcry_inactive = Color("ECECEC")
	self.colors.warcry_active = Color("efad29")
	self.colors.xp_breakdown_active_column = Color("dd9a38")
	self.colors.interaction_bar = Color("efad29")
	self.colors.teammate_interaction_bar = Color("efad29")
	self.colors.progress_green = Color("64bc4c")
	self.colors.progress_yellow = Color("efad29")
	self.colors.progress_orange = Color("dd5c23")
	self.colors.progress_red = Color("b8392e")
	self.colors.toast_notification_border = Color("222222")
	self.colors.turret_overheat = Color("c20015")
	self.colors.chat_border = Color("222222")
	self.colors.light_grey = Color("ECECEC")
	self.colors.chat_player_message = self.colors.raid_dirty_white
	self.colors.chat_peer_message = Color("F2F2F2")
	self.colors.chat_system_message = Color("ED2176") 
	self.colors.gold_orange = Color("c68e38")
	self.colors.intel_newspapers_text = Color("d6c8b2")
    self.colors.player_health_colors[1] = {
        start_percentage = 0.1,
        color = Color("b8392e")
    }
	 self.colors.player_health_colors[2] = {
        start_percentage = 0.25,
        color = Color("efad29")
    }
    self.colors.player_health_colors[3] = {
        start_percentage = 0.5,
        color = Color("64bc4c")
    }
	
	self.colors.player_stamina_colors[1] = {
        start_percentage = 0,
        color = Color("bc8b4c")
    }
	 self.colors.player_stamina_colors[2] = {
        start_percentage = 0.25,
        color = Color("a9bc4c")
    }
    self.colors.player_stamina_colors[3] = {
        start_percentage = 0.5,
        color = Color("4cafbc")
    }
	
	self.colors.ammo_clip_colors[1] = {
			start_percentage = 0,
			color = self.colors.progress_red
	}
	self.colors.ammo_clip_colors[3] = {
			start_percentage = 0.25,
			color = self.colors.light_grey
	}
	self.colors.ammo_clip_colors[2] = {
			start_percentage = 0.05,
			color = Color("f38212")
	}
	
end)
