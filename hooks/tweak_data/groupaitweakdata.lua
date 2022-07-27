Hooks:PostHook(GroupAITweakData, "_init_enemy_spawn_groups", "raidSE_init_enemy_spawn_groups", function(self, difficulty_index)
	if self._tactics.grunt_flankers then
		self._tactics.grunt_chargers = {
			"charge",
			"provide_coverfire",
			"provide_support"
		}
		self._tactics.gerbish_chargers = {
			"charge",
			"provide_coverfire",
			"provide_support"
		}
		self._tactics.fallschirm_chargers = {
			"charge",
			"provide_coverfire",
			"provide_support"
		}
		ss_chargers = {
			"charge",
			"provide_coverfire",
			"provide_support"
		}
		self._tactics.grunt_flankers = {
			"ranged_fire",
			"flank",
			"provide_coverfire",
			"provide_support"
		}
		self._tactics.gerbish_flankers = {
			"ranged_fire",
			"flank",
			"provide_coverfire",
			"provide_support"
		}
		self._tactics.commander = {
			"ranged_fire",
			"flank"
		}
	end

	--re-init the spawngroups using the new tactics tables
	self:_init_enemy_spawn_groups_german(difficulty_index)
	
	if self.enemy_spawn_groups.german.ss_rifle_range then
		if difficulty_index <= TweakData.DIFFICULTY_1 then
			self.enemy_spawn_groups.german.ss_rifle_range = {
				amount = {
					4,
					4
				},
				spawn = {
					{
						freq = 1,
						amount_min = 1,
						rank = 2,
						unit = "german_light",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 2,
						rank = 1,
						unit = "german_grunt_light",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 1,
						rank = 1,
						unit = "german_grunt_light_kar98",
						tactics = self._tactics.gerbish_rifle_range
					}
				}
			}
		elseif difficulty_index == TweakData.DIFFICULTY_2 then
			self.enemy_spawn_groups.german.ss_rifle_range = {
				amount = {
					4,
					4
				},
				spawn = {
					{
						freq = 1,
						amount_min = 2,
						rank = 2,
						unit = "german_light", --fixing this shouldn't matter, but just in case...it's typed in as german_light_ in vanilla
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 2,
						rank = 1,
						unit = "german_light_kar98",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 1,
						rank = 1,
						unit = "german_heavy_kar98",
						tactics = self._tactics.gerbish_rifle_range
					}
				}
			}
		elseif difficulty_index == TweakData.DIFFICULTY_3 then
			self.enemy_spawn_groups.german.ss_rifle_range = {
				amount = {
					4,
					4
				},
				spawn = {
					{
						freq = 1,
						amount_min = 2,
						rank = 2,
						unit = "german_light",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 2,
						rank = 1,
						unit = "german_light_kar98",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 2,
						amount_min = 1,
						rank = 1,
						unit = "german_heavy_kar98",
						tactics = self._tactics.gerbish_rifle_range
					}
				}
			}
		elseif difficulty_index == TweakData.DIFFICULTY_4 then
			self.enemy_spawn_groups.german.ss_rifle_range = {
				amount = {
					4,
					4
				},
				spawn = {
					{
						freq = 2,
						amount_min = 0,
						rank = 2,
						unit = "german_heavy",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 1,
						amount_min = 0,
						rank = 1,
						unit = "german_light_kar98",
						tactics = self._tactics.gerbish_rifle_range
					},
					{
						freq = 1,
						amount_min = 0,
						rank = 1,
						unit = "german_heavy_kar98",
						tactics = self._tactics.gerbish_rifle_range
					}
				}
			}
		end
	end
end)