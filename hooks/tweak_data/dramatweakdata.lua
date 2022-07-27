function DramaTweakData:init()
	self:_create_table_structure()

	self.drama_actions = {
		criminal_hurt = 0.5,
		criminal_dead = 0.2,
		criminal_disabled = 0.1
	}
	self.decay_period = 30
	self.max_dis = 6000
	self.max_dis_mul = 0.5
	self.low = 0.1
	self.peak = 0.9 --due to how updates work for groupai, above 95% drama cannot always be reached in a consistent manner, so we reduce it slightly
	self.assault_fade_end = 0.25
end