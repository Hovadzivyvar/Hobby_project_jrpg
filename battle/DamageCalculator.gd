extends Node
class_name DamageCalculator

const VARIANCE: float = 0.075  # ±7.5%

func calculate_player_damage(
		attacker: CharacterData,
		defender: EnemyData,
		ability: AbilityData,
		chain_multiplier: float) -> int:

	if ability.damage_type == AbilityData.DamageType.NONE:
		return 0

	# Base damage
	var base: float
	if ability.damage_type == AbilityData.DamageType.PHYSICAL:
		var atk = float(attacker.get_atk())
		var def = float(defender.get_def())
		print("Enemy DEF effective: ", def, " raw: ", defender.def,
					  " mod: ", defender.mod_def) 
		base = (atk * atk) / def
	else:
		var mag = float(attacker.get_mag())
		var spr = float(defender.get_spr())
		base = (mag * mag) / spr

	# Power modifier
	var power_mod = ability.power / 100.0

	# Hunter multiplier
	var hunter = attacker.get_hunter_multiplier(defender.get_type_string())

	# Element multiplier
	var element = _resolve_element(ability)
	var resistance = defender.get_resistance(element)
	var element_mod = 1.0 - resistance

	# DR multiplier
	var dr: float
	if ability.damage_type == AbilityData.DamageType.PHYSICAL:
		dr = defender.get_physical_dr()
	else:
		dr = defender.get_magic_dr()

	# Variance
	var variance = randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)

	# Final damage
	var damage = base * power_mod * chain_multiplier * hunter * element_mod * dr * variance
	# Handle absorption (element_mod negative = heals)
	print("base: ", base, " power: ", power_mod, " chain: ", chain_multiplier, 
		  " hunter: ", hunter, " element: ", element_mod, 
		  " dr: ", dr, " variance: ", variance, " final: ", damage)

	return int(damage)

func calculate_enemy_damage(
		attacker: EnemyData,
		defender: CharacterData,
		damage_type: AbilityData.DamageType = AbilityData.DamageType.PHYSICAL,
		element: CharacterData.Element = CharacterData.Element.NONE) -> int:

	if damage_type == AbilityData.DamageType.NONE:
		return 0

	# Base damage
	var base: float
	if damage_type == AbilityData.DamageType.PHYSICAL:
		var atk = float(attacker.get_atk())
		var def = float(defender.get_def())
		base = (atk * atk) / def
	else:
		var mag = float(attacker.get_mag())
		var spr = float(defender.get_spr())
		base = (mag * mag) / spr

	# Element multiplier
	var resistance = defender.get_resistance(element)
	var element_mod = 1.0 - resistance
	# DR multiplier
	var dr: float
	if damage_type == AbilityData.DamageType.PHYSICAL:
		dr = defender.get_physical_dr()
	else:
		dr = defender.get_magic_dr()

	# Variance
	var variance = randf_range(1.0 - VARIANCE, 1.0 + VARIANCE)

	# Final damage — enemy attacks have no chain or hunter
	var damage = base * element_mod * dr * variance
	return int(damage)

func apply_damage_to_enemy(
		damage: int,
		defender: EnemyData) -> int:
	# Handle absorption
	if damage < 0:
		defender.current_hp = min(defender.max_hp, defender.current_hp + abs(damage))
		return damage
	# Shield first
	var remaining = defender.absorb_damage(damage)
	defender.current_hp -= remaining
	defender.current_hp = max(0, defender.current_hp)
	return damage

func apply_damage_to_character(
		damage: int,
		defender: CharacterData) -> int:
	# Handle absorption
	if damage < 0:
		defender.current_hp = min(defender.max_hp, defender.current_hp + abs(damage))
		return damage
	# Shield first
	var remaining = defender.absorb_damage(damage)
	defender.current_hp -= remaining
	defender.current_hp = max(0, defender.current_hp)
	return damage

func apply_effect_to_enemy(
		ability: AbilityData,
		defender: EnemyData) -> void:
	print("Applying effect to ", defender.enemy_name,
				  " mod_def: ", ability.mod_def,
						  " immune: ", defender.immune_def_down)
						 
	if not ability.has_any_mods():
		return
	# Check stat debuff immunities
	var effect = ActiveEffect.from_ability(ability, defender.max_hp, ability.effect_is_removable)
	if defender.immune_atk_down and ability.mod_atk < 0.0:
		effect.mod_atk = 0.0
	if defender.immune_def_down and ability.mod_def < 0.0:
		effect.mod_def = 0.0
	if defender.immune_mag_down and ability.mod_mag < 0.0:
		effect.mod_mag = 0.0
	if defender.immune_spr_down and ability.mod_spr < 0.0:
		effect.mod_spr = 0.0
	# Elemental resistance mods always apply
	defender.apply_effect(effect)

func apply_effect_to_character(
		ability: AbilityData,
		defender: CharacterData) -> void:
	if not ability.has_any_mods() and ability.shield_flat == 0 and ability.shield_percent == 0.0:
		return
	var effect = ActiveEffect.from_ability(ability, defender.max_hp, ability.effect_is_removable)
	defender.apply_effect(effect)

func apply_healing_to_character(
		ability: AbilityData,
		defender: CharacterData,
		status_manager: StatusManager) -> int:
	var heal: int = 0
	if ability.heal_flat > 0:
		heal = ability.heal_flat
	elif ability.heal_percent > 0.0:
		heal = int(defender.max_hp * ability.heal_percent)
	heal = status_manager.apply_zombie_to_heal(heal, defender)
	if heal < 0:
		# Zombie — healing becomes damage
		defender.current_hp = max(0, defender.current_hp + heal)
	else:
		defender.current_hp = min(defender.max_hp, defender.current_hp + heal)
	return heal

func apply_revive_to_character(
		ability: AbilityData,
		defender: CharacterData,
		status_manager: StatusManager) -> int:
	if status_manager.apply_zombie_to_revive(defender):
		return 0
	var heal: int = 0
	if ability.heal_percent > 0.0:
		heal = int(defender.max_hp * ability.heal_percent)
	elif ability.heal_flat > 0:
		heal = ability.heal_flat
	defender.current_hp = heal
	defender.is_alive = true
	return heal

func _resolve_element(ability: AbilityData) -> CharacterData.Element:
	# Weapon element would be resolved here later
	return ability.element
