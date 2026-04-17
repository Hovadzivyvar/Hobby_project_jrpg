extends Resource
class_name AbilityData

enum AbilityType {
	OFFENSIVE,
	HEALING,
	BUFF,
	REVIVE,
	COVER
}

enum DamageType {
	NONE,
	PHYSICAL,
	MAGICAL
}

enum TargetType {
	SINGLE_ENEMY,
	SINGLE_ALLY,
	ALL_ENEMIES,
	ALL_ALLIES,
	SELF,
	ALL_ENEMIES_TAUNT 
}

enum CastRestriction {
	NONE,
	OFFENSIVE_ONLY,
	HEALING_ONLY,
	MAGIC_ONLY,
	PHYSICAL_ONLY
}

# Core identity
@export var ability_name: String = "Ability"
@export var description: String = ""
@export var mp_cost: int = 0

# Type
@export var ability_type: AbilityType = AbilityType.OFFENSIVE
@export var damage_type: DamageType = DamageType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY

# Damage properties
@export var element: CharacterData.Element = CharacterData.Element.NONE
@export var power: int = 100
@export var hits: int = 1

# Healing properties
@export var heal_percent: float = 0.0
@export var heal_flat: int = 0

# Buff properties — positive values for buffs, negative for debuffs
# Applied to target for buff_turns turns
@export var buff_turns: int = 0

# Stat modifiers (0.3 = +30%, -0.3 = -30%)
@export var mod_atk: float = 0.0
@export var mod_def: float = 0.0
@export var mod_mag: float = 0.0
@export var mod_spr: float = 0.0

# DR modifiers (0.3 = +30% DR, -0.3 = -30% DR)
@export var mod_physical_dr: float = 0.0
@export var mod_magic_dr: float = 0.0

# Elemental resistance modifiers (always apply, no immunity)
@export var mod_res_fire: float = 0.0
@export var mod_res_ice: float = 0.0
@export var mod_res_lightning: float = 0.0
@export var mod_res_water: float = 0.0
@export var mod_res_wind: float = 0.0
@export var mod_res_earth: float = 0.0
@export var mod_res_light: float = 0.0
@export var mod_res_dark: float = 0.0

# Cover properties
@export var cover_turns: int = 0
@export var cover_damage_reduction: float = 0.3  # 30% damage reduction for covering unit
@export var cover_party: bool = false             # true = cover whole party, false = single ally
# If true this ability removes all removable buffs/debuffs from target
@export var is_dispel: bool = false
@export var effect_is_removable: bool = true
# Shield properties
@export var shield_percent: float = 0.0  # % of max HP as shield
@export var shield_flat: int = 0         # flat shield amount
@export var shield_turns: int = 0
# MultiCast
@export var is_multi_cast: bool = false
@export var cast_count: int = 2
@export var cast_restriction: CastRestriction = CastRestriction.NONE

# Usage restrictions
@export var once_per_battle: bool = false
@export var cooldown_turns: int = 0  # 0 = no cooldown
@export var applies_taunt: bool = false
# Status effect to inflict
@export var inflicts_status: bool = false
@export var status_type: StatusEffect.Type = StatusEffect.Type.POISON
@export var status_duration: int = 3
@export var status_potency: float = 1.0
@export var status_chance: float = 1.0  # 1.0 = always if not resisted
@export var removes_statuses: bool = false
@export var status_removals: Array = []
# Helper functions
func is_offensive() -> bool:
	return ability_type == AbilityType.OFFENSIVE

func is_healing() -> bool:
	return ability_type == AbilityType.HEALING

func is_buff() -> bool:
	return ability_type == AbilityType.BUFF

func is_revive() -> bool:
	return ability_type == AbilityType.REVIVE

func is_cover() -> bool:
	return ability_type == AbilityType.COVER

func needs_ally_target() -> bool:
	return target_type == TargetType.SINGLE_ALLY

func uses_weapon_element() -> bool:
	return element == CharacterData.Element.NONE and damage_type == DamageType.PHYSICAL

func has_stat_mods() -> bool:
	return mod_atk != 0.0 or mod_def != 0.0 or mod_mag != 0.0 or mod_spr != 0.0

func has_dr_mods() -> bool:
	return mod_physical_dr != 0.0 or mod_magic_dr != 0.0

func has_elemental_mods() -> bool:
	return mod_res_fire != 0.0 or mod_res_ice != 0.0 or mod_res_lightning != 0.0 or \
		   mod_res_water != 0.0 or mod_res_wind != 0.0 or mod_res_earth != 0.0 or \
		   mod_res_light != 0.0 or mod_res_dark != 0.0

func has_any_mods() -> bool:
	return has_stat_mods() or has_dr_mods() or has_elemental_mods()
