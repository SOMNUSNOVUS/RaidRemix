HUDInteraction = HUDInteraction or class()

function HUDInteraction:init(hud, child_name)
	self._hud_panel = hud.panel
	self._progress_bar_width = 288 * 1.95
	self._progress_bar_height = 8 * 1.95
	self._progress_bar_x = self._hud_panel:w() / 2 - self._progress_bar_width / 2
	self._progress_bar_y = self._hud_panel:h() / 2 + 191
	self._progress_bar_bg = self._hud_panel:bitmap({
		name = "progress_bar_bg",
		layer = 2,
		visible = false,
		x = self._progress_bar_x,
		y = self._progress_bar_y,
		texture = tweak_data.gui.icons.interaction_hold_meter_bg.texture,
		texture_rect = tweak_data.gui.icons.interaction_hold_meter_bg.texture_rect,
		w = self._progress_bar_width,
		h = self._progress_bar_height
	})
	self._child_name_text = (child_name or "interact") .. "_text"
	self._child_ivalid_name_text = (child_name or "interact") .. "_invalid_text"

	if self._hud_panel:child(self._child_name_text) then
		self._hud_panel:remove(self._hud_panel:child(self._child_name_text))
	end

	if self._hud_panel:child(self._child_ivalid_name_text) then
		self._hud_panel:remove(self._hud_panel:child(self._child_ivalid_name_text))
	end

	local interact_text = self._hud_panel:text({
		layer = 1,
		h = 68,
		font_size = 32,
		align = "center",
		text = "HELLO",
		visible = false,
		valign = "center",
		name = self._child_name_text,
		color = Color.white,
		font = tweak_data.gui.fonts.din_compressed_outlined_32
	})
	local invalid_text = self._hud_panel:text({
		layer = 3,
		h = 68,
		text = "HELLO",
		font_size = 32,
		align = "center",
		blend_mode = "normal",
		visible = false,
		valign = "center",
		name = self._child_ivalid_name_text,
		color = Color(1, 0.3, 0.3),
		font = tweak_data.gui.fonts.din_compressed_outlined_32
	})

	interact_text:set_center_y(self._hud_panel:h() / 2 + 100)
	invalid_text:set_center_y(self._hud_panel:h() / 2 + 100)

	self._panels_being_animated = {}
end

function HUDInteraction:show_interaction_bar(current, total)
	self:remove_interact()

	if self._progress_bar then
		self._progress_bar:parent():remove(self._progress_bar)

		self._progress_bar = nil
	end

	self._progress_bar = self._hud_panel:rect({
		w = 0,
		name = "interaction_progress_bar_show",
		h = 0,
		alpha = 0.8,
		blend_mode = "normal",
		layer = 3,
		x = self._progress_bar_x,
		y = self._progress_bar_y,
		color = tweak_data.gui.colors.interaction_bar
	})

	self._progress_bar_bg:set_visible(true)
	self._progress_bar:animate(callback(self, self, "_animate_interaction_start"), 0.25)
end

function HUDInteraction:animate_progress(duration)
	if not self._progress_bar then
		self:show_interaction_bar(0, duration)
	end

	self._auto_animation = self._progress_bar:animate(callback(self, self, "_animate_interaction_duration"), duration)
end

function HUDInteraction:hide_interaction_bar(complete, show_interact_at_finish)
	if complete then
		local progress_full = self._hud_panel:rect({
			name = "interaction_progress_bar_hide",
			alpha = 1,
			blend_mode = "normal",
			layer = 3,
			x = self._progress_bar_x,
			y = self._progress_bar_y,
			w = self._progress_bar_width,
			h = self._progress_bar_height,
			color = Color(0.8666666666666667, 0.6039215686274509, 0.2196078431372549)
		})

		progress_full:animate(callback(self, self, "_animate_interaction_complete"))
	end

	if self._progress_bar then
		local progress_cancel = self._hud_panel:rect({
			name = "interaction_progress_bar_cancel",
			alpha = 1,
			blend_mode = "normal",
			layer = 3,
			x = self._progress_bar_x,
			y = self._progress_bar_y,
			w = self._progress_bar:w(),
			h = self._progress_bar:h(),
			color = Color(0.8666666666666667, 0.6039215686274509, 0.2196078431372549)
		})

		progress_cancel:animate(callback(self, self, "_animate_interaction_cancel"), 0.15)
		self._progress_bar:stop()
		self._progress_bar:parent():remove(self._progress_bar)
		self._progress_bar_bg:set_visible(false)

		self._progress_bar = nil

		if show_interact_at_finish then
			self:show_interact()
		end
	end
end

function HUDInteraction:_animate_interaction_start(progress_bar, duration)
	local t = 0
	self._panels_being_animated[tostring(progress_bar)] = true

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local current_height = self:_ease_out_quint(t, 0, self._progress_bar_height, duration)

		progress_bar:set_height(current_height)
		progress_bar:set_y(self._progress_bar_y)
	end

	progress_bar:set_height(self._progress_bar_height)

	self._panels_being_animated[tostring(progress_bar)] = false
end

function HUDInteraction:_animate_interaction_duration(progress_bar, duration)
	local t = 0

	self:set_interaction_bar_width(0, duration)

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt

		self:set_interaction_bar_width(t, duration)
	end

	self:set_interaction_bar_width(duration, duration)
end

function HUDInteraction:_animate_interaction_cancel(progress_bar, duration)
	local t = 0
	local start_height = progress_bar:h()

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local current_height = self:_ease_in_quint(t, start_height, -start_height, duration)

		progress_bar:set_height(current_height)
		progress_bar:set_y(self._progress_bar_y)
	end

	progress_bar:set_height(0)
	progress_bar:parent():remove(progress_bar)
end

function HUDInteraction:_animate_interaction_complete(progress_bar)
	local duration = 1
	local t = 0

	progress_bar:set_halign("right")

	while t < duration do
		local dt = coroutine.yield()
		t = t + dt
		local current_width = self:_ease_out_quint(t, self._progress_bar_width, -self._progress_bar_width, duration)

		progress_bar:set_width(current_width)
		progress_bar:set_right(self._hud_panel:w() / 2 + self._progress_bar_width / 2)
	end

	progress_bar:set_width(0)
	progress_bar:parent():remove(progress_bar)
end

