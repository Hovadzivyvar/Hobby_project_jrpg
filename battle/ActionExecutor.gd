extends Node
class_name ActionExecutor

const HIT_DELAY: float = 0.075

var blocks: Array[CharacterBlock] = []
var enemy_blocks: Array[EnemyBlock] = []
var damage_calculator: DamageCalculator = null
var chain_manager: ChainManager = null
var battle_scene: Node2D = null
var get_selected_enemy: Callable
var status_manager: StatusManager = null

signal enemy_defeated(enemy_block: EnemyBlock)
signal damage_spawned(enemy_block: EnemyBlock, damage: int, multiplier: float)
signal enemy_hp_updated
signal character_refreshed(target: CharacterData)

func setup(
		p_blocks: Array[CharacterBlock],
		p_enemy_blocks: Array[EnemyBlock],
		p_damage_calculator: DamageCalculator,
		p_chain_manager: ChainManager,
		p_get_selected_enemy: Callable,
		p_status_manager: StatusManager) -> void:
	blocks = p_blocks
	enemy_blocks = p_enemy_blocks
	damage_calculator = p_damage_calculator
	chain_manager = p_chain_manager
	get_selected_enemy = p_get_selected_enemy
	status_manager = p_status_manager

func get_basic_attack_ability(character: CharacterData) -> AbilityData:
	var basic = AbilityData.new()
	basic.ability_name = "Attack"
	basic.ability_type = AbilityData.AbilityType.OFFENSIVE
	basic.damage_type = AbilityData.DamageType.PHYSICAL
	basic.element = CharacterData.Element.NONE
	basic.power = 100
	basic.hits = character.hits
	return basic

func get_defense_ability() -> AbilityData:
	var defense = AbilityData.new()
	defense.ability_name = "Defense"
	defense.ability_type = AbilityData.AbilityType.BUFF
	defense.damage_type = AbilityData.DamageType.NONE
	defense.target_type = AbilityData.TargetType.SELF
	defense.buff_turns = 1
	defense.mod_physical_dr = -0.3
	defense.mod_magic_dr = -0.3
	defense.mp_cost = 0
	return defense

func execute_block_actions(block: CharacterBlock) -> void:
	if not status_manager.can_act(block.character_data):
		print(block.character_data.char_name, " cannot act due to status")
		return
	if block.pending_abilities.is_empty() and block.pending_item == null:
		return
	var target_index: int = 0
	for i in range(block.pending_abilities.size()):
		var ability = block.pending_abilities[i]
		if ability.damage_type == AbilityData.DamageType.MAGICAL and \
		not status_manager.can_use_magic(block.character_data):
			print(block.character_data.char_name, " is silenced!")
			continue
		if ability.is_offensive():
			var current_enemy = get_selected_enemy.call()
			if not current_enemy or not is_instance_valid(current_enemy) or \
					current_enemy.enemy_data.current_hp <= 0:
				if enemy_blocks.is_empty():
					return
				enemy_hp_updated.emit()
				return
			await execute_hits_with_ability(block, ability)
		elif ability.applies_taunt:
			var current_enemy = get_selected_enemy.call()
			var taunt_target = block.targeted_enemy if block.targeted_enemy else current_enemy
			if ability.target_type == AbilityData.TargetType.ALL_ENEMIES_TAUNT:
				for enemy_block in enemy_blocks:
					if not enemy_block.enemy_data.immune_taunt:
						apply_taunt_to_enemy(enemy_block, block.character_data, ability)
			else:
				if taunt_target and is_instance_valid(taunt_target) and \
						not taunt_target.enemy_data.immune_taunt:
					apply_taunt_to_enemy(taunt_target, block.character_data, ability)
				elif taunt_target and is_instance_valid(taunt_target) and \
						taunt_target.enemy_data.immune_taunt:
					print(taunt_target.enemy_data.enemy_name, " is immune to taunt")
		else:
			var target: CharacterData = null
			if target_index < block.pending_targets.size():
				target = block.pending_targets[target_index]
			target_index += 1
			execute_ally_action_with_ability(block, ability, target)
		block.character_data.current_mp = max(0,
			block.character_data.current_mp - ability.mp_cost)
		block.character_data.register_ability_used(ability)
		character_refreshed.emit(block.character_data)
	if block.pending_item:
		execute_item_action(block)


func execute_hits_with_ability(
		block: CharacterBlock,
		ability: AbilityData) -> void:
	var attacker = block.character_data
	var hit_count = ability.hits
	var target_enemy = get_selected_enemy.call()
	if not target_enemy or not is_instance_valid(target_enemy) or \
			target_enemy.enemy_data.current_hp <= 0:
		if enemy_blocks.is_empty():
			return
		return
	for i in range(hit_count):
		target_enemy = get_selected_enemy.call()
		if not target_enemy or not is_instance_valid(target_enemy) or \
				target_enemy.enemy_data.current_hp <= 0:
			break
		if enemy_blocks.is_empty():
			return
		var chain_mult = chain_manager.register_hit(attacker, target_enemy)
		var damage = damage_calculator.calculate_player_damage(
			attacker, target_enemy.enemy_data, ability, chain_mult)
		chain_manager.add_to_total(target_enemy, damage)
		damage_calculator.apply_damage_to_enemy(damage, target_enemy.enemy_data)
		enemy_hp_updated.emit()
		damage_spawned.emit(target_enemy, damage, chain_mult)
		if target_enemy.enemy_data.current_hp <= 0:
			enemy_defeated.emit(target_enemy)
			break
		await get_tree().create_timer(HIT_DELAY).timeout
	target_enemy = get_selected_enemy.call()
	if ability.has_any_mods() and target_enemy and is_instance_valid(target_enemy):
		damage_calculator.apply_effect_to_enemy(ability, target_enemy.enemy_data)

func execute_ally_action_with_ability(
		block: CharacterBlock,
		ability: AbilityData,
		target: CharacterData) -> void:
	if not target and ability.target_type != AbilityData.TargetType.SELF:
		return
	var actual_target = target if target else block.character_data
	match ability.ability_type:
		AbilityData.AbilityType.HEALING:
			var heal = damage_calculator.apply_healing_to_character(
		ability, actual_target, status_manager)
		# wake from sleep if healing damages zombie
			if heal > 0:
				status_manager.wake_from_sleep(actual_target)
			print("%s heals %s for %d" % [block.character_data.char_name,
			actual_target.char_name, abs(heal)])
		AbilityData.AbilityType.REVIVE:
			var heal = damage_calculator.apply_revive_to_character(
			ability, actual_target, status_manager)
			print("%s revives %s with %d HP" % [block.character_data.char_name,
		actual_target.char_name, heal])
		AbilityData.AbilityType.BUFF:
			#var actual_target = target if target else block.character_data
	# Remove statuses first if ability does that
			if ability.removes_statuses and status_manager:
				status_manager.remove_specific_statuses(
			actual_target, ability.status_removals)
	# Then apply buff effects as normal
			damage_calculator.apply_effect_to_character(ability, actual_target)
			if ability.applies_taunt:
				actual_target.is_taunting = true
				actual_target.taunt_turns_remaining = ability.buff_turns
				print("%s taunts enemies" % actual_target.char_name)
			print("%s buffs %s" % [block.character_data.char_name, actual_target.char_name])
			refresh_character_block(actual_target)
		AbilityData.AbilityType.COVER:
			block.character_data.is_covering_ally = null
			block.character_data.is_party_covering = false
			if ability.cover_party:
				block.character_data.is_party_covering = true
			else:
				block.character_data.is_covering_ally = actual_target
			block.character_data.cover_turns_remaining = ability.cover_turns
			block.character_data.cover_damage_reduction = ability.cover_damage_reduction
			print("%s covers %s" % [block.character_data.char_name,
				"party" if ability.cover_party else actual_target.char_name])
	character_refreshed.emit(actual_target)

func execute_item_action(block: CharacterBlock) -> void:
	var item = block.pending_item
	if not item:
		return
	var target: CharacterData = null
	if not block.pending_targets.is_empty():
		target = block.pending_targets[0]
	if not target:
		return
	match item.item_type:
		ItemData.ItemType.HEALING_HP:
			target.current_hp = min(target.max_hp, target.current_hp + item.heal_amount)
			print("Used %s on %s, restored %d HP" % [item.item_name,
				target.char_name, item.heal_amount])
			GameState.remove_item(item)
		ItemData.ItemType.HEALING_MP:
			target.current_mp = min(target.max_mp, target.current_mp + item.heal_amount)
			print("Used %s on %s, restored %d MP" % [item.item_name,
				target.char_name, item.heal_amount])
			GameState.remove_item(item)
	character_refreshed.emit(target)

func apply_taunt_to_enemy(
		enemy_block: EnemyBlock,
		taunter: CharacterData,
		ability: AbilityData) -> void:
	enemy_block.enemy_data.taunted_by = taunter
	enemy_block.enemy_data.taunt_turns_remaining = ability.buff_turns
	print(taunter.char_name, " taunts ", enemy_block.enemy_data.enemy_name)

func refresh_character_block(target: CharacterData) -> void:
	for block in blocks:
		if block.character_data == target:
			block.update_hp()
			block.update_mp()
			if target.is_alive and target.current_hp > 0 and not block.has_fired:
				block.modulate = Color(1, 1, 1)
			break
