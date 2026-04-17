extends Resource
class_name CharacterData

enum Element {
	NONE, FIRE, ICE, LIGHTNING, WATER, WIND, EARTH, LIGHT, DARK
}

# Core identity
@export var char_name: String = "Unit"
@export var is_alive: bool = true

# Core stats
@export var max_hp: int = 1000
@export var current_hp: int = 1000
@export var max_mp: int = 100
@export var current_mp: int = 100
@export var atk: int = 100
@export var def: int = 50
@export var mag: int = 100
@export var spr: int = 50

# Abilities
@export var abilities: Array[AbilityData] = []
@export var hits: int = 2
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

# Hunter multipliers — summed from passives/gear
# Example: beast_hunter = 0.5 means +50% damage vs beasts
@export var hunter_human: float = 0.0
@export var hunter_beast: float = 0.0
@export var hunter_aquatic: float = 0.0
@export var hunter_bird: float = 0.0
@export var hunter_insect: float = 0.0
@export var hunter_plant: float = 0.0
@export var hunter_stone: float = 0.0
@export var hunter_undead: float = 0.0
@export var hunter_demon: float = 0.0
@export var hunter_machine: float = 0.0
@export var hunter_dragon: float = 0.0

# Damage reduction — modified by buffs
var physical_dr: float = 1.0
var magic_dr: float = 1.0
# Runtime stat modifiers from buffs
var mod_atk: float = 0.0
var mod_def: float = 0.0
var mod_mag: float = 0.0
var mod_spr: float = 0.0

# Runtime DR modifiers
var mod_physical_dr: float = 0.0
var mod_magic_dr: float = 0.0

# Runtime elemental resistance modifiers
var mod_res_fire: float = 0.0
var mod_res_ice: float = 0.0
var mod_res_lightning: float = 0.0
var mod_res_water: float = 0.0
var mod_res_wind: float = 0.0
var mod_res_earth: float = 0.0
var mod_res_light: float = 0.0
var mod_res_dark: float = 0.0

# Taunt
var is_taunting: bool = false
var taunt_turns_remaining: int = 0

# Cover state
var is_covering_ally: CharacterData = null  # who this unit is covering
var cover_turns_remaining: int = 0
var cover_damage_reduction: float = 0.0
var is_party_covering: bool = false
# Runtime active effects
var active_effects: Array[ActiveEffect] = []
var current_shield: int = 0
var shield_turns_remaining: int = 0
# Track ability usage for restrictions
var abilities_used_this_battle: Array[AbilityData] = []
var ability_cooldowns: Dictionary = {}  # AbilityData -> turns remaining
# Active statuses
var active_statuses: Array[StatusEffect] = []

# Status resistances 0.0 = no resistance, 1.0 = immune
@export var res_status_poison: float = 0.0
@export var res_status_blind: float = 0.0
@export var res_status_sleep: float = 0.0
@export var res_status_silence: float = 0.0
@export var res_status_paralyze: float = 0.0
@export var res_status_confuse: float = 0.0
@export var res_status_petrify: float = 0.0
@export var res_status_zombie: float = 0.0

# Runtime status resistance modifiers from gear/abilities
var mod_res_status_poison: float = 0.0
var mod_res_status_blind: float = 0.0
var mod_res_status_sleep: float = 0.0
var mod_res_status_silence: float = 0.0
var mod_res_status_paralyze: float = 0.0
var mod_res_status_confuse: float = 0.0
var mod_res_status_petrify: float = 0.0
var mod_res_status_zombie: float = 0.0

# Effective stat getters
func get_atk() -> int:
	return max(1, int(atk * (1.0 + mod_atk)))

func get_def() -> int:
	return max(1, int(def * (1.0 + mod_def)))

func get_mag() -> int:
	return max(1, int(mag * (1.0 + mod_mag)))

func get_spr() -> int:
	return max(1, int(spr * (1.0 + mod_spr)))

func get_physical_dr() -> float:
	return physical_dr * (1.0 + mod_physical_dr) 

func get_magic_dr() -> float:
	return magic_dr * (1.0 + mod_magic_dr) 

func get_resistance(element: Element) -> float:
	match element:
		Element.FIRE:       return res_fire + mod_res_fire
		Element.ICE:        return res_ice + mod_res_ice
		Element.LIGHTNING:  return res_lightning + mod_res_lightning
		Element.WATER:      return res_water + mod_res_water
		Element.WIND:       return res_wind + mod_res_wind
		Element.EARTH:      return res_earth + mod_res_earth
		Element.LIGHT:      return res_light + mod_res_light
		Element.DARK:       return res_dark + mod_res_dark
		_:                  return 0.0

func get_hunter_multiplier(enemy_type: String) -> float:
	match enemy_type:
		"Human":    return 1.0 + hunter_human
		"Beast":    return 1.0 + hunter_beast
		"Aquatic":  return 1.0 + hunter_aquatic
		"Bird":     return 1.0 + hunter_bird
		"Insect":   return 1.0 + hunter_insect
		"Plant":    return 1.0 + hunter_plant
		"Stone":    return 1.0 + hunter_stone
		"Undead":   return 1.0 + hunter_undead
		"Demon":    return 1.0 + hunter_demon
		"Machine":  return 1.0 + hunter_machine
		"Dragon":   return 1.0 + hunter_dragon
		_:          return 1.0
		
func apply_effect(effect: ActiveEffect) -> void:
	active_effects.append(effect)
	# Initialize shield when effect is first applied
	if effect.shield_amount > 0:
		if effect.shield_amount > current_shield:
			current_shield = effect.shield_amount
			shield_turns_remaining = effect.shield_turns
	# Recalculate other modifiers but not shield
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
	# Tick shield duration independently
	if shield_turns_remaining > 0:
		shield_turns_remaining -= 1
		if shield_turns_remaining <= 0:
			current_shield = 0
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
	mod_physical_dr = _get_strongest("mod_physical_dr")
	mod_magic_dr = _get_strongest("mod_magic_dr")
	mod_res_fire = _get_strongest("mod_res_fire")
	mod_res_ice = _get_strongest("mod_res_ice")
	mod_res_lightning = _get_strongest("mod_res_lightning")
	mod_res_water = _get_strongest("mod_res_water")
	mod_res_wind = _get_strongest("mod_res_wind")
	mod_res_earth = _get_strongest("mod_res_earth")
	mod_res_light = _get_strongest("mod_res_light")
	mod_res_dark = _get_strongest("mod_res_dark")
	# Shield — strongest applies
	#var shield = _get_strongest_shield()
	#current_shield = shield[0]
	#shield_turns_remaining = shield[1]

		
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
	
func can_use_ability(ability: AbilityData) -> bool:
	if ability.once_per_battle and ability in abilities_used_this_battle:
		return false
	if ability_cooldowns.has(ability) and ability_cooldowns[ability] > 0:
		return false
	return true

func register_ability_used(ability: AbilityData) -> void:
	if ability.once_per_battle:
		abilities_used_this_battle.append(ability)
	if ability.cooldown_turns > 0:
		ability_cooldowns[ability] = ability.cooldown_turns

func tick_cooldowns() -> void:
	for ability in ability_cooldowns.keys():
		ability_cooldowns[ability] -= 1
		if ability_cooldowns[ability] <= 0:
			ability_cooldowns.erase(ability)

func tick_cover_and_taunt() -> void:
	# Tick cover
	if cover_turns_remaining > 0:
		cover_turns_remaining -= 1
		if cover_turns_remaining <= 0:
			is_covering_ally = null
			is_party_covering = false
			print(char_name, " cover expired")
	# Tick taunt
	if taunt_turns_remaining > 0:
		taunt_turns_remaining -= 1
		if taunt_turns_remaining <= 0:
			is_taunting = false
			print(char_name, " taunt expired")

func get_status_resistance(status_type: StatusEffect.Type) -> float:
	match status_type:
		StatusEffect.Type.POISON:   
			return min(1.0, res_status_poison + mod_res_status_poison)
		StatusEffect.Type.BLIND:    
			return min(1.0, res_status_blind + mod_res_status_blind)
		StatusEffect.Type.SLEEP:    
			return min(1.0, res_status_sleep + mod_res_status_sleep)
		StatusEffect.Type.SILENCE:  
			return min(1.0, res_status_silence + mod_res_status_silence)
		StatusEffect.Type.PARALYZE: 
			return min(1.0, res_status_paralyze + mod_res_status_paralyze)
		StatusEffect.Type.CONFUSE:  
			return min(1.0, res_status_confuse + mod_res_status_confuse)
		StatusEffect.Type.PETRIFY:  
			return min(1.0, res_status_petrify + mod_res_status_petrify)
		StatusEffect.Type.ZOMBIE:   
			return min(1.0, res_status_zombie + mod_res_status_zombie)
		_: return 0.0
