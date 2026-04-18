extends Node
class_name TurnManager

signal player_turn_started
signal enemy_turn_started
signal round_reset
signal party_defeated
#signal all_enemies_defeated
signal enemy_action_used(enemy_name: String, action_name: String)

const ENEMY_ACTION_DELAY: float = 0.5

var fired_count: int = 0
var blocks: Array[CharacterBlock] = []
var enemy_blocks: Array[EnemyBlock] = []
var selected_enemy: EnemyBlock = null
var damage_calculator: DamageCalculator
var enemy_ai: EnemyAI = null
var status_manager: StatusManager = null

func setup(
		p_blocks: Array[CharacterBlock],
		p_enemy_blocks: Array[EnemyBlock],
		p_damage_calculator: DamageCalculator,
		p_enemy_ai: EnemyAI,
		p_status_manager: StatusManager ) -> void:
	blocks = p_blocks
	enemy_blocks = p_enemy_blocks
	damage_calculator = p_damage_calculator
	enemy_ai = p_enemy_ai
	status_manager = p_status_manager

func register_fired() -> void:
	fired_count += 1
	var can_act_count = blocks.filter(func(b): return b.character_data.is_alive and status_manager.can_act(b.character_data)).size()
	if fired_count >= can_act_count:
		start_enemy_phase()

func set_selected_enemy(enemy_block: EnemyBlock) -> void:
	selected_enemy = enemy_block

func start_enemy_phase() -> void:
	enemy_turn_started.emit()
	await _run_enemy_attacks()
	reset_round()

func _run_enemy_attacks() -> void:
	enemy_ai.start_new_round()

	for enemy_block in enemy_blocks:
		if enemy_block.enemy_data.current_hp <= 0:
			continue
		print("Enemy: ", enemy_block.enemy_data.enemy_name,
			" taunted_by: ", enemy_block.enemy_data.taunted_by,
			" taunt_turns: ", enemy_block.enemy_data.taunt_turns_remaining)
		var taunter_get = _get_taunting_character(enemy_block)
		print("Taunter found: ", taunter_get)
		# Refresh alive party before each enemy action
		var alive_party = blocks.filter(func(b): return b.character_data.is_alive)
		if alive_party.is_empty():
			party_defeated.emit()
			return

		var decision = enemy_ai.decide_action(enemy_block.enemy_data, alive_party)
		var action: EnemyAction = decision["action"]
		var target_block: CharacterBlock = decision["target"]

		# Handle taunt override
		var is_aoe = action and action.ability and (
			action.ability.target_type == AbilityData.TargetType.ALL_ALLIES or
			action.ability.target_type == AbilityData.TargetType.ALL_ENEMIES)

		var taunter = _get_taunting_character(enemy_block)
		print("Taunter: ", taunter, " immune: ", enemy_block.enemy_data.immune_taunt) 
		if not is_aoe and taunter and not enemy_block.enemy_data.immune_taunt:
			print("Target overridden to: ", target_block.character_data.char_name)
			target_block = taunter
		else:
			# Verify target is still alive, reselect if not
			print("Taunt not applied, target stays: ", 
		target_block.character_data.char_name if target_block else "null")
			if target_block and not target_block.character_data.is_alive:
				target_block = alive_party[randi() % alive_party.size()]
										
		# Handle cover
		if target_block:
			var coverer = _get_coverer(target_block.character_data)
			#print("Cover check for: ", target_block.character_data.char_name,
			#		  " coverer: ", coverer)
			if coverer:
				target_block = coverer

		await _execute_enemy_action(enemy_block, action, target_block, alive_party)
		await Engine.get_main_loop().create_timer(ENEMY_ACTION_DELAY).timeout


func _get_random_alive_target() -> CharacterBlock:
	var alive = blocks.filter(func(b): return b.character_data.is_alive)
	if alive.is_empty():
		return null
	return alive[randi() % alive.size()]

func _apply_character_damage(block: CharacterBlock, damage: int) -> void:
	var _remaining = damage_calculator.apply_damage_to_character(damage, block.character_data)
	# Wake from sleep on damage
	if status_manager and damage > 0:
		status_manager.wake_from_sleep(block.character_data)
					
	block.update_hp()
	character_damaged.emit(block, damage)
	if block.character_data.current_hp <= 0:
		block.set_defeated()
		print(block.character_data.char_name, " defeated!")
		_check_party_defeated()

func _check_party_defeated() -> void:
	var alive = blocks.filter(func(b): return b.character_data.is_alive)
	if alive.is_empty():
		party_defeated.emit()

func reset_round() -> void:
	fired_count = 0
	status_manager.tick_all_statuses()
	for block in blocks:
		block.reset()
	round_reset.emit()
	player_turn_started.emit()

signal character_damaged(block: CharacterBlock, damage: int)

func _execute_enemy_action(
		enemy_block: EnemyBlock,
		action: EnemyAction,
		target_block: CharacterBlock,
		_alive_party: Array[CharacterBlock]) -> void:
	var ability = action.ability if action and action.ability else null
	await get_tree().process_frame
	var action_name = action.action_name if action else "Attack"
	enemy_action_used.emit(enemy_block.enemy_data.enemy_name, action_name)
	# Handle self targeting for buffs
	if action and action.target_strategy == EnemyAction.TargetStrategy.SELF:
		if ability:
			# Apply buff to self — enemy buffing itself
			enemy_block.enemy_data.apply_effect(
				ActiveEffect.from_ability(ability, enemy_block.enemy_data.max_hp, false))
			print(enemy_block.enemy_data.enemy_name, " buffs itself")
		return

	if not target_block:
		return

	# Calculate and apply damage
	var damage_type = ability.damage_type if ability else AbilityData.DamageType.PHYSICAL
	var element = ability.element if ability else CharacterData.Element.NONE
	var damage = damage_calculator.calculate_enemy_damage(
		enemy_block.enemy_data,
		target_block.character_data,
		damage_type,
		element)
		
	# After applying damage:
			
		# Apply debuffs to target if ability has mods
	if ability and ability.has_any_mods():
		var effect = ActiveEffect.from_ability(
			ability, target_block.character_data.max_hp, ability.effect_is_removable)
		target_block.character_data.apply_effect(effect)

	# Apply cover damage reduction if covering
	var coverer = _get_coverer(target_block.character_data)
	if coverer and coverer != target_block:
		damage = int(damage * (1.0 - coverer.character_data.cover_damage_reduction))

	_apply_character_damage(target_block, damage)
	print(enemy_block.enemy_data.enemy_name, " hits ",
		target_block.character_data.char_name, " for ", damage)
		
	if ability and ability.inflicts_status and target_block:
		var chance_roll = randf()
		if chance_roll <= ability.status_chance:
			status_manager.try_apply_status(
			target_block.character_data,
			ability.status_type,
			ability.status_duration,
			ability.status_potency)
		

func _get_coverer(target: CharacterData) -> CharacterBlock:
	# Check party cover first
	for block in blocks:
		#print("Checking cover: ", block.character_data.char_name,
		#" party_cover: ", block.character_data.is_party_covering,
		#" covering_ally: ", block.character_data.is_covering_ally,
		#" target: ", target)
		if block.character_data.is_alive and block.character_data.is_party_covering:
			return block
	# Check single ally cover
	for block in blocks:
		if block.character_data.is_alive and \
				block.character_data.is_covering_ally == target:
			return block
	return null

func _get_taunting_character(enemy_block: EnemyBlock) -> CharacterBlock:
	# Check if this specific enemy is taunted
	if enemy_block.enemy_data.taunted_by:
		for block in blocks:
			if block.character_data == enemy_block.enemy_data.taunted_by \
					and block.character_data.is_alive:
				return block
	# Check global taunt
	for block in blocks:
		if block.character_data.is_alive and block.character_data.is_taunting:
			return block
	return null
