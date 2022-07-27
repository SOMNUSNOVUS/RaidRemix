function CharacterTweakData:_init_german_light(presets)
	self.german_light = deep_clone(presets.base)
	self.german_light.experience = {}
	self.german_light.weapon = presets.weapon.expert
	self.german_light.detection = presets.detection.normal
	self.german_light.vision = presets.vision.normal
	self.german_light.HEALTH_INIT = 500
	self.german_light.BASE_HEALTH_INIT = 500
	self.german_light.headshot_dmg_mul = 1
	self.german_light.move_speed = presets.move_speed.fast
	self.german_light.surrender_break_time = {
		10,
		15
	}
	self.german_light.suppression = presets.suppression.hard_agg
	self.german_light.surrender = presets.surrender.normal
	self.german_light.ecm_vulnerability = 1
	self.german_light.ecm_hurts = {
		ears = {
			max_duration = 10,
			min_duration = 8
		}
	}
	self.german_light.weapon_voice = "1"
	self.german_light.experience.cable_tie = "tie_swat"
	self.german_light.speech_prefix_p1 = "ger"
	self.german_light.speech_prefix_p2 = "elite"
	self.german_light.speech_prefix_count = 4
	self.german_light.access = "swat"
	self.german_light.silent_priority_shout = "shout_loud_soldier"
	self.german_light.dodge = presets.dodge.athletic
	self.german_light.deathguard = true
	self.german_light.chatter = presets.enemy_chatter.cop
	self.german_light.steal_loot = true
	self.german_light.no_retreat = true
	self.german_light.no_arrest = true
	self.german_light.loot_table = "hard_enemy"
	self.german_light.type = CharacterTweakData.ENEMY_TYPE_ELITE
	self.german_light.carry_tweak_corpse = "german_black_waffen_sentry_light_body"
	self.german_light_kar98 = clone(self.german_light)
	self.german_light_shotgun = clone(self.german_light)

	table.insert(self._enemies_list, "german_light")
	table.insert(self._enemies_list, "german_light_kar98")
	table.insert(self._enemies_list, "german_light_shotgun")
end

function CharacterTweakData:_init_german_heavy(presets)
	self.german_heavy = deep_clone(presets.base)
	self.german_heavy.experience = {}
	self.german_heavy.weapon = presets.weapon.expert
	self.german_heavy.detection = presets.detection.normal
	self.german_heavy.vision = presets.vision.normal
	self.german_heavy.HEALTH_INIT = 700
	self.german_heavy.BASE_HEALTH_INIT = 700
	self.german_heavy.headshot_dmg_mul = 1
	self.german_heavy.move_speed = presets.move_speed.normal
	self.german_heavy.crouch_move = false
	self.german_heavy.surrender_break_time = {
		10,
		15
	}
	self.german_heavy.suppression = presets.suppression.hard_agg
	self.german_heavy.surrender = presets.surrender.normal
	self.german_heavy.ecm_vulnerability = 1
	self.german_heavy.ecm_hurts = {
		ears = {
			max_duration = 10,
			min_duration = 8
		}
	}
	self.german_heavy.weapon_voice = "1"
	self.german_heavy.experience.cable_tie = "tie_swat"
	self.german_heavy.speech_prefix_p1 = "ger"
	self.german_heavy.speech_prefix_p2 = "elite"
	self.german_heavy.speech_prefix_count = 4
	self.german_heavy.access = "swat"
	self.german_heavy.silent_priority_shout = "shout_loud_soldier"
	self.german_heavy.dodge = presets.dodge.heavy
	self.german_heavy.deathguard = true
	self.german_heavy.chatter = presets.enemy_chatter.cop
	self.german_heavy.steal_loot = true
	self.german_heavy.no_retreat = true
	self.german_heavy.no_arrest = true
	self.german_heavy.loot_table = "elite_enemy"
	self.german_heavy.type = CharacterTweakData.ENEMY_TYPE_ELITE
	self.german_heavy.carry_tweak_corpse = "german_black_waffen_sentry_heavy_body"
	self.german_heavy_mp38 = clone(self.german_heavy)
	self.german_heavy_kar98 = clone(self.german_heavy)
	self.german_heavy_shotgun = clone(self.german_heavy)

	table.insert(self._enemies_list, "german_heavy")
	table.insert(self._enemies_list, "german_heavy_mp38")
	table.insert(self._enemies_list, "german_heavy_kar98")
	table.insert(self._enemies_list, "german_heavy_shotgun")
end

function CharacterTweakData:_init_german_gasmask(presets)
	self.german_gasmask = deep_clone(presets.base)
	self.german_gasmask.experience = {}
	self.german_gasmask.weapon = presets.weapon.expert
	self.german_gasmask.detection = presets.detection.normal
	self.german_gasmask.vision = presets.vision.hard
	self.german_gasmask.HEALTH_INIT = 600
	self.german_gasmask.BASE_HEALTH_INIT = 600
	self.german_gasmask.headshot_dmg_mul = 1
	self.german_gasmask.move_speed = presets.move_speed.normal
	self.german_gasmask.crouch_move = false
	self.german_gasmask.surrender_break_time = {
		10,
		15
	}
	self.german_gasmask.suppression = presets.suppression.hard_agg
	self.german_gasmask.surrender = presets.surrender.normal
	self.german_gasmask.ecm_vulnerability = 1
	self.german_gasmask.ecm_hurts = {
		ears = {
			max_duration = 10,
			min_duration = 8
		}
	}
	self.german_gasmask.weapon_voice = "1"
	self.german_gasmask.experience.cable_tie = "tie_swat"
	self.german_gasmask.speech_prefix_p1 = "ger"
	self.german_gasmask.speech_prefix_p2 = "elite"
	self.german_gasmask.speech_prefix_count = 4
	self.german_gasmask.access = "swat"
	self.german_gasmask.silent_priority_shout = "shout_loud_soldier"
	self.german_gasmask.dodge = presets.dodge.average
	self.german_gasmask.deathguard = true
	self.german_gasmask.chatter = presets.enemy_chatter.cop
	self.german_gasmask.steal_loot = true
	self.german_gasmask.no_retreat = true
	self.german_gasmask.no_arrest = true
	self.german_gasmask.loot_table = "elite_enemy"
	self.german_gasmask.type = CharacterTweakData.ENEMY_TYPE_ELITE
	self.german_gasmask.carry_tweak_corpse = "german_black_waffen_sentry_gasmask_body"
	self.german_gasmask_shotgun = clone(self.german_gasmask)

	table.insert(self._enemies_list, "german_gasmask")
	table.insert(self._enemies_list, "german_gasmask_shotgun")
end

function CharacterTweakData:_init_german_commander_backup(presets)
	self.german_light_commander_backup = deep_clone(self.german_light)
	self.german_light_commander_backup.carry_tweak_corpse = "german_black_waffen_sentry_light_commander_body"
	self.german_light_commander_backup.weapon = presets.weapon.insane

	table.insert(self._enemies_list, "german_light_commander_backup")

	self.german_heavy_commander_backup = deep_clone(self.german_heavy)
	self.german_heavy_commander_backup.carry_tweak_corpse = "german_black_waffen_sentry_heavy_commander_body"
	self.german_heavy_commander_backup.weapon = presets.weapon.insane

	table.insert(self._enemies_list, "german_heavy_commander_backup")

	self.german_gasmask_commander_backup = deep_clone(self.german_gasmask)
	self.german_gasmask_commander_backup.weapon = presets.weapon.insane

	table.insert(self._enemies_list, "german_gasmask_commander_backup")

	self.german_gasmask_commander_backup_shotgun = deep_clone(self.german_gasmask_commander_backup)

	table.insert(self._enemies_list, "german_gasmask_commander_backup_shotgun")
end

function CharacterTweakData:_init_german_sniper(presets)
	self.german_sniper = deep_clone(presets.base)
	self.german_sniper.experience = {}
	self.german_sniper.detection = presets.detection.sniper
	self.german_sniper.vision = presets.vision.easy
	self.german_sniper.HEALTH_INIT = 160
	self.german_sniper.BASE_HEALTH_INIT = 160
	self.german_sniper.headshot_dmg_mul = 1
	self.german_sniper.allowed_stances = {
		cbt = true
	}
	self.german_sniper.move_speed = presets.move_speed.normal
	self.german_sniper.shoot_logic_req = "sniper"
	self.german_sniper.suppression = nil
	self.german_sniper.no_retreat = true
	self.german_sniper.no_arrest = true
	self.german_sniper.loot_table = "normal_enemy"
	self.german_sniper.surrender = nil
	self.german_sniper.ecm_vulnerability = 0
	self.german_sniper.ecm_hurts = {
		ears = {
			max_duration = 9,
			min_duration = 7
		}
	}
	self.german_sniper.priority_shout = "shout_loud_sniper"
	self.german_sniper.rescue_hostages = false
	self.german_sniper.deathguard = false
	self.german_sniper.no_equip_anim = true
	self.german_sniper.wall_fwd_offset = 100
	self.german_sniper.damage.explosion_damage_mul = 1
	self.german_sniper.calls_in = nil
	self.german_sniper.use_animation_on_fire_damage = true
	self.german_sniper.flammable = true
	self.german_sniper.weapon = presets.weapon.sniper

	self:_process_weapon_usage_table(self.german_sniper.weapon)

	self.german_sniper.weapon_voice = "1"
	self.german_sniper.experience.cable_tie = "tie_swat"
	self.german_sniper.speech_prefix_p1 = "ger"
	self.german_sniper.speech_prefix_p2 = "elite"
	self.german_sniper.speech_prefix_count = 4
	self.german_sniper.access = "sniper"
	self.german_sniper.chatter = presets.enemy_chatter.no_chatter
	self.german_sniper.announce_incomming = "incomming_sniper"
	self.german_sniper.dodge = presets.dodge.athletic
	self.german_sniper.steal_loot = nil
	self.german_sniper.use_animation_on_fire_damage = false
	self.german_sniper.type = CharacterTweakData.ENEMY_TYPE_ELITE
	self.german_sniper.dismemberment_enabled = false
	self.german_sniper.is_special = true
	self.german_sniper.special_type = CharacterTweakData.SPECIAL_UNIT_TYPE_SNIPER
	self.german_sniper.damage.hurt_severity = deep_clone(presets.hurt_severities.base)
	self.german_sniper.damage.hurt_severity.bullet = {
		health_reference = "current",
		zones = {
			{
				none = 1,
				health_limit = 0.01
			},
			{
				heavy = 0,
				health_limit = 0.3,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				health_limit = 0.6,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				health_limit = 0.9,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				light = 0,
				moderate = 0,
				none = 1
			}
		}
	}

	table.insert(self._enemies_list, "german_sniper")
end

function CharacterTweakData:_init_german_spotter(presets)
	self.german_spotter = deep_clone(presets.base)
	self.german_spotter.experience = {}
	self.german_spotter.weapon = presets.weapon.expert
	self.german_spotter.detection = presets.detection.normal
	self.german_spotter.vision = presets.vision.spotter
	self.german_spotter.shoot_logic_req = "spotter"
	self.german_spotter.HEALTH_INIT = 80
	self.german_spotter.BASE_HEALTH_INIT = 80
	self.german_spotter.headshot_dmg_mul = nil
	self.german_spotter.move_speed = presets.move_speed.slow
	self.german_spotter.crouch_move = false
	self.german_spotter.surrender_break_time = {
		10,
		15
	}
	self.german_spotter.suppression = presets.suppression.hard_agg
	self.german_spotter.surrender = presets.surrender.normal
	self.german_spotter.ecm_vulnerability = 1
	self.german_spotter.ecm_hurts = {
		ears = {
			max_duration = 10,
			min_duration = 8
		}
	}
	self.german_spotter.weapon_voice = "1"
	self.german_spotter.experience.cable_tie = "tie_swat"
	self.german_spotter.speech_prefix_p1 = "ger"
	self.german_spotter.speech_prefix_p2 = "elite"
	self.german_spotter.speech_prefix_count = 4
	self.german_spotter.access = "sniper"
	self.german_spotter.silent_priority_shout = "f37"
	self.german_spotter.priority_shout = "shout_loud_spotter"
	self.german_spotter.dodge = presets.dodge.poor
	self.german_spotter.deathguard = true
	self.german_spotter.chatter = presets.enemy_chatter.cop
	self.german_spotter.steal_loot = true
	self.german_spotter.no_retreat = true
	self.german_spotter.no_arrest = true
	self.german_spotter.loot_table = "normal_enemy"
	self.german_spotter.type = CharacterTweakData.ENEMY_TYPE_ELITE
	self.german_spotter.damage.hurt_severity = deep_clone(presets.hurt_severities.base)
	self.german_spotter.damage.hurt_severity.bullet = {
		health_reference = "current",
		zones = {
			{
				none = 1,
				health_limit = 0.01
			},
			{
				heavy = 0,
				health_limit = 0.3,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				health_limit = 0.6,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				health_limit = 0.9,
				light = 0,
				moderate = 0,
				none = 1
			},
			{
				heavy = 0,
				light = 0,
				moderate = 0,
				none = 1
			}
		}
	}
	self.german_spotter.dismemberment_enabled = false
	self.german_spotter.is_special = true
	self.german_spotter.special_type = CharacterTweakData.SPECIAL_UNIT_TYPE_SPOTTER

	table.insert(self._enemies_list, "german_spotter")
end

function CharacterTweakData:_init_russian(presets)
	self.russian = {
		damage = presets.gang_member_damage
	}
	self.russian.damage.hurt_severity = deep_clone(presets.hurt_severities.only_explosion_hurts)
	self.russian.weapon = deep_clone(presets.weapon.gang_member)
	self.russian.HEALTH_INIT = 400
	self.russian.weapon.weapons_of_choice = {
		primary = Idstring("units/vanilla/weapons/wpn_npc_usa_garand/wpn_npc_usa_garand"),
		secondary = Idstring("units/vanilla/weapons/wpn_npc_usa_garand/wpn_npc_usa_garand")
	}
	self.russian.detection = presets.detection.gang_member
	self.russian.dodge = presets.dodge.average
	self.russian.move_speed = presets.move_speed.fast
	self.russian.no_run_stop = true
	self.russian.crouch_move = false
	self.russian.speech_prefix = "russ"
	self.russian.weapon_voice = "1"
	self.russian.access = "teamAI1"
	self.russian.arrest = {
		timeout = 2400,
		aggression_timeout = 6,
		arrest_timeout = 2400
	}
	self.russian.access = "teamAI1"
	self.russian.vision = presets.vision.special_forces
end

function CharacterTweakData:_init_german(presets)
	self.german = {
		damage = presets.gang_member_damage
	}
	self.german.damage.hurt_severity = deep_clone(presets.hurt_severities.only_explosion_hurts)
	self.german.weapon = deep_clone(presets.weapon.gang_member)
	self.german.HEALTH_INIT = 400
	self.german.weapon.weapons_of_choice = {
		primary = Idstring("units/vanilla/weapons/wpn_npc_smg_thompson/wpn_npc_smg_thompson"),
		secondary = Idstring("units/vanilla/weapons/wpn_npc_smg_thompson/wpn_npc_smg_thompson")
	}
	self.german.detection = presets.detection.gang_member
	self.german.dodge = presets.dodge.average
	self.german.move_speed = presets.move_speed.fast
	self.german.no_run_stop = true
	self.german.crouch_move = false
	self.german.speech_prefix = "germ"
	self.german.weapon_voice = "2"
	self.german.access = "teamAI1"
	self.german.arrest = {
		timeout = 2400,
		aggression_timeout = 6,
		arrest_timeout = 2400
	}
	self.german.vision = presets.vision.special_forces
end

function CharacterTweakData:_init_british(presets)
	self.british = {
		damage = presets.gang_member_damage
	}
	self.british.damage.hurt_severity = deep_clone(presets.hurt_severities.only_explosion_hurts)
	self.british.weapon = deep_clone(presets.weapon.gang_member)
	self.british.HEALTH_INIT = 400
	self.british.weapon.weapons_of_choice = {
		primary = Idstring("units/vanilla/weapons/wpn_npc_usa_garand/wpn_npc_usa_garand"),
		secondary = Idstring("units/vanilla/weapons/wpn_npc_usa_garand/wpn_npc_usa_garand")
	}
	self.british.detection = presets.detection.gang_member
	self.british.dodge = presets.dodge.average
	self.british.move_speed = presets.move_speed.fast
	self.british.no_run_stop = true
	self.british.crouch_move = false
	self.british.speech_prefix = "brit"
	self.british.weapon_voice = "3"
	self.british.access = "teamAI1"
	self.british.arrest = {
		timeout = 2400,
		aggression_timeout = 6,
		arrest_timeout = 2400
	}
	self.british.vision = presets.vision.special_forces
end

function CharacterTweakData:_init_american(presets)
	self.american = {
		damage = presets.gang_member_damage
	}
	self.american.damage.hurt_severity = deep_clone(presets.hurt_severities.only_explosion_hurts)
	self.american.weapon = deep_clone(presets.weapon.gang_member)
	self.american.HEALTH_INIT = 400
	self.american.weapon.weapons_of_choice = {
		primary = Idstring("units/vanilla/weapons/wpn_npc_smg_thompson/wpn_npc_smg_thompson"),
		secondary = Idstring("units/vanilla/weapons/wpn_npc_smg_thompson/wpn_npc_smg_thompson")
	}
	self.american.detection = presets.detection.gang_member
	self.american.dodge = presets.dodge.average
	self.american.move_speed = presets.move_speed.fast
	self.american.no_run_stop = true
	self.american.crouch_move = false
	self.american.speech_prefix = "amer"
	self.american.weapon_voice = "3"
	self.american.access = "teamAI1"
	self.american.arrest = {
		timeout = 2400,
		aggression_timeout = 6,
		arrest_timeout = 2400
	}
	self.american.vision = presets.vision.special_forces
end