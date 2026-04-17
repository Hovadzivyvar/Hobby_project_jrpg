extends Resource
class_name EnemyData

enum EnemyType {
	HUMAN, BEAST, AQUATIC, BIRD, INSECT,
	PLANT, STONE, UNDEAD, DEMON, MACHINE, DRAGON
}

# Core identity
@export var enemy_name: String = "Enemy"
@export var enemy_type: EnemyType = EnemyType.BEAST

# Core stats
@export var max_hp: int = 5000
@export var current_hp: int = 5000
@export var atk: int = 100
@export var def: int = 50
@export var mag: int = 100
@export var spr: int = 50

# Innate damage reduction
# 1.0 = no reduction, 0.7 = 30% reduction
@export var physical_dr: float = 1.0
@export var magic_dr: float = 1.0

# Elemental resistances
# 0.0 = neutral, -0.5 = weak, 0.5 = resist, 1.0 = immune, >1.0 = absorb
@export var res_fire: float = 0.0
@export var res_ice: float = 0.0
@export var res_lightning: float = 0.0
@export var res_water: float = 0.0
@export var res_wind: float = 0.0
@export var res_earth: float = 0.0
@export var res_light: float = 0.0
@export var res_dark: float = 0.0
# Stat debuff immunities
@export var immune_atk_down: bool = false
@export var immune_def_down: bool = false
@export var immune_mag_down: bool = false
@export var immune_spr_down: bool = false
 

# Runtime DR modifiers from buffs/debuffs
var physical_dr_modifier: float = 0.0
var magic_dr_modifier: float = 0.0

# Runtime stat modifiers from debuffs
var mod_atk: float = 0.0
var mod_def: float = 0.0
var mod_mag: float = 0.0
var mod_spr: float = 0.0
# Runtime elemental resistance modifiers
var mod_res_fire: float = 0.0
var mod_res_ice: float = 0.0
var mod_res_lightning: float = 0.0
var mod_res_water: float = 0.0
var mod_res_wind: float = 0.0
var mod_res_earth: float = 0.0
var mod_res_light: float = 0.0
var mod_res_dark: float = 0.0
# Runtime active effects
var active_effects: Array[ActiveEffect] = []
var current_shield: int = 0
var shield_turns_remaining: int = 0
@export var is_boss: bool = false
@export var immune_taunt: bool = false
@export var action_pool: Array[EnemyAction] = []

# Boss only
@export var pattern: Array[EnemyAction] = []
@export var hp_thresholds: Dictionary = {}
# Example: {0.5: threshold_action, 0.25: threshold_action}
var pattern_index: int = 0
var triggered_thresholds: Array[float] = []
var reset_pattern_on_threshold: bool = false
var taunted_by: CharacterData = null
var taunt_turns_remaining: int = 0
@export var res_status_poison: float = 0.0
@export var res_status_blind: float = 0.0
@export var res_status_sleep: float = 0.0
@export var res_status_silence: float = 0.0
@export var res_status_paralyze: float = 0.0
@export var res_status_confuse: float = 0.0
@export var res_status_petrify: float = 0.0
@export var res_status_zombie: float = 0.0

var active_statuses: Array[StatusEffect] = []

func get_physical_dr() -> float:
	return physical_dr * (1.0 + physical_dr_modifier) 

func get_magic_dr() -> float:
	return magic_dr * (1.0 + magic_dr_modifier) 

func get_type_string() -> String:
	match enemy_type:
		EnemyType.HUMAN:    return "Human"
		EnemyType.BEAST:    return "Beast"
		EnemyType.AQUATIC:  return "Aquatic"
		EnemyType.BIRD:     return "Bird"
		EnemyType.INSECT:   return "Insect"
		EnemyType.PLANT:    return "Plant"
		EnemyType.STONE:    return "Stone"
		EnemyType.UNDEAD:   return "Undead"
		EnemyType.DEMON:    return "Demon"
		EnemyType.MACHINE:  return "Machine"
		EnemyType.DRAGON:   return "Dragon"
		_:                  return "Unknown"

# Effective stat getters (base + modifiers)
func get_atk() -> int:
	return max(1, int(atk * (1.0 + mod_atk)))

func get_def() -> int:
	return max(1, int(def * (1.0 + mod_def)))

func get_mag() -> int:
	return max(1, int(mag * (1.0 + mod_mag)))

func get_spr() -> int:
	return max(1, int(spr * (1.0 + mod_spr)))

func get_resistance(element: CharacterData.Element) -> float:
	match element:
		CharacterData.Element.FIRE:         return res_fire + mod_res_fire
		CharacterData.Element.ICE:          return res_ice + mod_res_ice
		CharacterData.Element.LIGHTNING:    return res_lightning + mod_res_lightning
		CharacterData.Element.WATER:        return res_water + mod_res_water
		CharacterData.Element.WIND:         return res_wind + mod_res_wind
		CharacterData.Element.EARTH:        return res_earth + mod_res_earth
		CharacterData.Element.LIGHT:        return res_light + mod_res_light
		CharacterData.Element.DARK:         return res_dark + mod_res_dark
		_:                                  return 0.0

func apply_effect(effect: ActiveEffect) -> void:
	active_effects.append(effect)
	_recalculate_modifiers()

func remove_removable_effects() -> void:
	active_effects = active_effects.filter(
		func(e): return not e.is_removable)
	_recalculate_modifiers()

func tick_effects() -> void:
	for effect in active_effects:
		if effect.turns_remaining > 0:
			effect.turns_remaining -= 1
		if effect.shield_turns > 0:
			effect.shield_turns -= 1
	active_effects = active_effects.filter(
		func(e): return e.turns_remaining > 0)
	_recalculate_modifiers()

func _get_strongest(modifier: String) -> float:
	var strongest: float = 0.0
	for effect in active_effects:
		var value = effect.get(modifier)
		# For positive buffs take highest positive
		# For negative debuffs take lowest negative
		if abs(value) > abs(strongest):
			strongest = value
	return strongest

func _get_strongest_shield() -> Array:
	# Returns [amount, turns] of strongest active shield
	var best_amount: int = 0
	var best_turns: int = 0
	for effect in active_effects:
		if effect.shield_amount > best_amount:
			best_amount = effect.shield_amount
		elif effect.shield_amount == best_amount and effect.shield_turns > best_turns:
			best_turns = effect.shield_turns
	return [best_amount, best_turns]


func _recalculate_modifiers() -> void:
	# Use strongest per modifier type
	mod_atk = _get_strongest("mod_atk")
	mod_def = _get_strongest("mod_def")
	mod_mag = _get_strongest("mod_mag")
	mod_spr = _get_strongest("mod_spr")
	physical_dr_modifier = _get_strongest("mod_physical_dr")
	magic_dr_modifier = _get_strongest("mod_magic_dr")
	mod_res_fire = _get_strongest("mod_res_fire")
	mod_res_ice = _get_strongest("mod_res_ice")
	mod_res_lightning = _get_strongest("mod_res_lightning")
	mod_res_water = _get_strongest("mod_res_water")
	mod_res_wind = _get_strongest("mod_res_wind")
	mod_res_earth = _get_strongest("mod_res_earth")
	mod_res_light = _get_strongest("mod_res_light")
	mod_res_dark = _get_strongest("mod_res_dark")
	# Shield — strongest applies
	var shield = _get_strongest_shield()
	current_shield = shield[0]
	shield_turns_remaining = shield[1]

		
func absorb_damage(damage: int) -> int:
	if current_shield <= 0:
		return damage
	if damage <= current_shield:
		current_shield -= damage
		return 0
	var remainder = damage - current_shield
	current_shield = 0
	shield_turns_remaining = 0
	return remainder

func tick_taunt() -> void:
	if taunt_turns_remaining > 0:
		taunt_turns_remaining -= 1
		if taunt_turns_remaining <= 0:
			taunted_by = null

func get_status_resistance(status_type: StatusEffect.Type) -> float:
	match status_type:
		StatusEffect.Type.POISON:   return res_status_poison
		StatusEffect.Type.BLIND:    return res_status_blind
		StatusEffect.Type.SLEEP:    return res_status_sleep
		StatusEffect.Type.SILENCE:  return res_status_silence
		StatusEffect.Type.PARALYZE: return res_status_paralyze
		StatusEffect.Type.CONFUSE:  return res_status_confuse
		StatusEffect.Type.PETRIFY:  return res_status_petrify
		StatusEffect.Type.ZOMBIE:   return res_status_zombie
		_: return 0.0
