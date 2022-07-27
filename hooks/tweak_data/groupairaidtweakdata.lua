Hooks:PostHook(GroupAIRaidTweakData, "init", "raid_init", function(self, difficulty_index)
	self.assault.force = {
		10,
		12,
		14
	}
	self.assault.force_pool = {
		32,
		64,
		100
	}
	
	if difficulty_index <= TweakData.DIFFICULTY_1 then
		self.assault.force_balance_mul = {
			0.8,
			1.15,
			1.25,
			1.75
		}
		self.assault.force_pool_balance_mul = {
			0.5,
			0.75,
			0.8,
			1
		}
	elseif difficulty_index == TweakData.DIFFICULTY_2 then
		self.assault.force_balance_mul = {
			1,
			1.25,
			1.5,
			2.25
		}
		self.assault.force_pool_balance_mul = {
			0.8,
			1.25,
			1.6,
			2
		}
	elseif difficulty_index == TweakData.DIFFICULTY_3 then
		self.assault.force_balance_mul = {
			1,
			1.25,
			1.5,
			2.25
		}
		self.assault.force_pool_balance_mul = {
			1,
			1.25,
			1.5,
			2.25
		}
	elseif difficulty_index == TweakData.DIFFICULTY_4 then
		self.assault.force_balance_mul = {
			1,
			1.25,
			1.5,
			2.25
		}
		self.assault.force_pool_balance_mul = {
			1,
			1.25,
			1.5,
			2.25
		}
	end

	if difficulty_index <= TweakData.DIFFICULTY_1 then
		self.recurring_group_SO = {
			recurring_spawn_1 = {
				interval = {
					30,
					60
				}
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_2 then
		self.recurring_group_SO = {
			recurring_spawn_1 = {
				interval = {
					30,
					60
				}
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_3 then
		self.recurring_group_SO = {
			recurring_spawn_1 = {
				interval = {
					20,
					40
				}
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_4 then
		self.recurring_group_SO = {
			recurring_spawn_1 = {
				interval = {
					20,
					40
				}
			}
		}
	else
		debug_pause("[GroupAIRaidTweakData:init] Unknown difficulty_index", difficulty_index)
	end
	
	if difficulty_index <= TweakData.DIFFICULTY_1 then
		self.assault.delay = {80, 70, 30}
	elseif difficulty_index == TweakData.DIFFICULTY_2 then
		self.assault.delay = {80, 60, 30}
	elseif difficulty_index == TweakData.DIFFICULTY_3 then
		self.assault.delay = {80, 60, 30}
	elseif difficulty_index == TweakData.DIFFICULTY_4 then
		self.assault.delay = {60, 50, 25}
	end

	if difficulty_index <= TweakData.DIFFICULTY_1 then
		self.assault.groups = {
			grunt_flankers = {
				50,
				50,
				50
			},
			grunt_chargers = {
				50,
				50,
				50
			},
			grunt_support_range = {
				40,
				40,
				40
			},
			gerbish_chargers = {
				0,
				50,
				50
			},
			gerbish_rifle_range = {
				0,
				0,
				0
			},
			gerbish_flankers = {
				0,
				0,
				50
			},
			fallschirm_charge = {
				0,
				0,
				0
			},
			fallschirm_support = {
				0,
				0,
				0
			},
			fallschirm_flankers = {
				0,
				0,
				0
			},
			ss_flankers = {
				0,
				0,
				0
			},
			ss_rifle_range = {
				0,
				0,
				0
			},
			ss_chargers = {
				0,
				0,
				0
			},
			flamethrower = {
				0,
				4,
				8
			},
			commanders = {
				0,
				4,
				8
			},
			commander_squad = {
				60,
				60,
				60
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_2 then
		self.assault.groups = {
			grunt_flankers = {
				50,
				50,
				50
			},
			grunt_chargers = {
				50,
				60,
				0
			},
			grunt_support_range = {
				40,
				40,
				40
			},
			gerbish_chargers = {
				40,
				50,
				50
			},
			gerbish_rifle_range = {
				30,
				40,
				30
			},
			gerbish_flankers = {
				30,
				50,
				50
			},
			fallschirm_charge = {
				0,
				0,
				0
			},
			fallschirm_support = {
				0,
				0,
				0
			},
			fallschirm_flankers = {
				0,
				0,
				0
			},
			ss_flankers = {
				0,
				0,
				0
			},
			ss_rifle_range = {
				0,
				0,
				0
			},
			ss_chargers = {
				0,
				0,
				0
			},
			flamethrower = {
				0,
				4,
				8
			},
			commanders = {
				0,
				4,
				8
			},
			commander_squad = {
				60,
				60,
				60
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_3 then
		self.assault.groups = {
			grunt_chargers = {
				0,
				0,
				0
			},
			grunt_flankers = {
				0,
				0,
				0
			},
			grunt_support_range = {
				0,
				0,
				0
			},
			gerbish_chargers = {
				50,
				50,
				30
			},
			gerbish_rifle_range = {
				40,
				40,
				20
			},
			gerbish_flankers = {
				50,
				50,
				30
			},
			fallschirm_charge = {
				30,
				50,
				50
			},
			fallschirm_support = {
				0,
				40,
				40
			},
			fallschirm_flankers = {
				0,
				50,
				50
			},
			ss_flankers = {
				0,
				0,
				0
			},
			ss_rifle_range = {
				0,
				0,
				0
			},
			ss_chargers = {
				0,
				0,
				0
			},
			flamethrower = {
				6,
				9,
				12
			},
			commanders = {
				6,
				9,
				12
			},
			commander_squad = {
				60,
				60,
				60
			}
		}
	elseif difficulty_index == TweakData.DIFFICULTY_4 then
		self.assault.groups = {
			grunt_chargers = {
				0,
				0,
				0
			},
			grunt_flankers = {
				0,
				0,
				0
			},
			grunt_support_range = {
				0,
				0,
				0
			},
			gerbish_chargers = {
				0,
				0,
				0
			},
			gerbish_rifle_range = {
				0,
				0,
				0
			},
			gerbish_flankers = {
				0,
				0,
				0
			},
			fallschirm_charge = {
				50,
				50,
				40
			},
			fallschirm_support = {
				40,
				40,
				30
			},
			fallschirm_flankers = {
				50,
				50,
				40
			},
			ss_flankers = {
				30,
				50,
				50
			},
			ss_rifle_range = {
				0,
				40,
				50
			},
			ss_chargers = {
				30,
				50,
				50
			},
			flamethrower = {
				15,
				18,
				20
			},
			commanders = {
				15,
				18,
				20
			},
			commander_squad = {
				60,
				60,
				60
			}
		}
	end
end)
