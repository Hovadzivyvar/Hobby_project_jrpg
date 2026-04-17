extends Resource
class_name ActiveEffect

var source_ability: AbilityData = null
var turns_remaining: int = 0
var is_removable: bool = true

# Modifier values
var mod_atk: float = 0.0
var mod_def: float = 0.0
var mod_mag: float = 0.0
var mod_spr: float = 0.0
var mod_physical_dr: float = 0.0
var mod_magic_dr: float = 0.0
var mod_res_fire: float = 0.0
var mod_res_ice: float = 0.0
var mod_res_lightning: float = 0.0
var mod_res_water: float = 0.0
var mod_res_wind: float = 0.0
var mod_res_earth: float = 0.0
var mod_res_light: float = 0.0
var mod_res_dark: float = 0.0

# Shield
var shield_amount: int = 0
var shield_turns: int = 0

static func from_ability(
		ability: AbilityData,
		max_hp: int,
		removable: bool = true) -> ActiveEffect:
	var effect = ActiveEffect.new()
	effect.source_ability = ability
	effect.turns_remaining = ability.buff_turns
	effect.is_removable = removable
	effect.mod_atk = ability.mod_atk
	effect.mod_def = ability.mod_def
	effect.mod_mag = ability.mod_mag
	effect.mod_spr = ability.mod_spr
	effect.mod_physical_dr = ability.mod_physical_dr
	effect.mod_magic_dr = ability.mod_magic_dr
	effect.mod_res_fire = ability.mod_res_fire
	effect.mod_res_ice = ability.mod_res_ice
	effect.mod_res_lightning = ability.mod_res_lightning
	effect.mod_res_water = ability.mod_res_water
	effect.mod_res_wind = ability.mod_res_wind
	effect.mod_res_earth = ability.mod_res_earth
	effect.mod_res_light = ability.mod_res_light
	effect.mod_res_dark = ability.mod_res_dark
	# Calculate shield amount
	if ability.shield_flat > 0:
		effect.shield_amount = ability.shield_flat
	elif ability.shield_percent > 0.0:
		effect.shield_amount = int(max_hp * ability.shield_percent)
	effect.shield_turns = ability.shield_turns
	return effect
