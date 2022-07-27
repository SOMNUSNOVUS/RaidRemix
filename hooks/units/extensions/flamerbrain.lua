--just be fucking normal

function FlamerBrain:init(unit)
	FlamerBrain.super.init(self, unit)

	self._unit:sound_source():post_event("flamer_breathing_start")
	
	self.is_flamer = true
	
	self._flamer_effect_table = {
		effect = Idstring("effects/vanilla/character/flamer_eyes"),
		parent = self._unit:get_object(Idstring("Head"))
	}
	
	self._flamer_effect = World:effect_manager():spawn(self._flamer_effect_table)
end

function FlamerBrain:pre_destroy(unit)
	FlamerBrain.super.pre_destroy(self, unit)
	
	if self._flamer_effect then
		World:effect_manager():fade_kill(self._flamer_effect)
		self._flamer_effect = nil
		self._flamer_effect_table = nil
	end
end