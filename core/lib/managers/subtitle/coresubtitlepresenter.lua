
core:module("CoreSubtitlePresenter")
core:import("CoreClass")
core:import("CoreCode")
core:import("CoreEvent")
core:import("CoreDebug")
core:import("CoreSubtitleSequence")

SubtitlePresenter = SubtitlePresenter or CoreClass.class()
DebugPresenter = DebugPresenter or CoreClass.class(SubtitlePresenter)
OverlayPresenter = OverlayPresenter or CoreClass.class(SubtitlePresenter)

function OverlayPresenter:show_text(text, duration, color, nationality_icon)
log(tostring(color))
	if text == nil or text == "" then
		return
	end

	local label = self.__subtitle_panel:child("label") or self.__subtitle_panel:text({
		name = "label",
		vertical = "top",
		wrap = true,
		align = "center",
		y = 1,
		x = 32,
		layer = 1,
		font = self.__font_name,
		font_size = self.__font_size,
		color = Color.white
	})
	local shadow = self.__subtitle_panel:child("shadow") or self.__subtitle_panel:text({
		y = 2,
		name = "shadow",
		vertical = "top",
		wrap = true,
		align = "center",
		word_wrap = true,
		visible = true,
		x = 33,
		layer = 0,
		font = self.__font_name,
		font_size = self.__font_size,
		color = Color.black:with_alpha(0.5)
	})

	label:set_w(self.__subtitle_panel:w() - 64)
	shadow:set_w(self.__subtitle_panel:w() - 64)

	if nationality_icon ~= nil then
		local nation_icon = self.__subtitle_panel:child("nation_icon") or self.__subtitle_panel:bitmap({
			name = "nation_icon",
			h = 32,
			y = 1,
			w = 32,
			layer = 1,
			visible = true,
			x = 1,
			texture = nationality_icon.texture,
			texture_rect = nationality_icon.texture_rect
		})

		nation_icon:set_image(nationality_icon.texture)
		nation_icon:set_texture_rect(unpack(nationality_icon.texture_rect))
		nation_icon:set_visible(true)

		local string_len = self:_string_width(text)
		local new_x = math.max(1, self.__subtitle_panel:w() / 2 - string_len / 2 - 32 - 3)

		nation_icon:set_x(new_x)
		label:set_color(Color.white)
	else
		label:set_color(color or Color.white)

		if self.__subtitle_panel:child("nation_icon") then
			self.__subtitle_panel:child("nation_icon"):set_visible(false)
		end
	end

	label:set_text(text)
	shadow:set_text(text)
end
