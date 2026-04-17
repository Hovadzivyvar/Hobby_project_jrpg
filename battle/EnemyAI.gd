extends Node
class_name EnemyAI

# Condition priority order — higher index = higher priority
const CONDITION_PRIORITY = [
	EnemyAction.Condition.ALWAYS,
	EnemyAction.Condition.FIRST_TURN_ONLY,
	EnemyAction.Condition.ALLY_ENEMY_DEAD,
	EnemyAction.Condition.PARTY_HAS_BUFFS,
	EnemyAction.Condition.SELF_LOW_HP,
	EnemyAction.Condition.SELF_CRITICAL_HP
]

var turn_number: int = 0
var enemy_died_this_round: bool = false

func reset() -> void:
	turn_number = 0
	enemy_died_this_round = false

func start_new_round() -> void:
	turn_number += 1
	enemy_died_this_round = false

func notify_enemy_died() -> void:
	enemy_died_this_round = true

func decide_action(
		enemy: EnemyData,
		alive_party: Array[CharacterBlock]) -> Dictionary:
	# Returns {action: EnemyAction, target: CharacterBlock}

	# Check HP thresholds for bosses first
	if enemy.is_boss:
		var threshold_action = _check_thresholds(enemy)
		if threshold_action:
			var threshold_target  = _select_target(threshold_action, alive_party, enemy)
			return {"action": threshold_action, "target": threshold_target}

	# Get valid actions sorted by condition priority
	var action = _pick_action(enemy, alive_party)
	if not action:
		# Fallback basic attack
		action = EnemyAction.new()
		action.target_strategy = EnemyAction.TargetStrategy.RANDOM_ALIVE

	var target = _select_target(action, alive_party, enemy)
	return {"action": action, "target": target}

func _check_thresholds(enemy: EnemyData) -> EnemyAction:
	var hp_percent = float(enemy.current_hp) / float(enemy.max_hp)
	# Check thresholds from lowest to highest so lowest HP triggers first
	var sorted_thresholds = enemy.hp_thresholds.keys()
	sorted_thresholds.sort()
	for threshold in sorted_thresholds:
		if hp_percent <= threshold and \
				not threshold in enemy.triggered_thresholds:
			enemy.triggered_thresholds.append(threshold)
			var threshold_data = enemy.hp_thresholds[threshold]
			if threshold_data.get("reset_pattern", false):
				enemy.pattern_index = 0
			return threshold_data.get("action", null)
	return null

func _pick_action(
		enemy: EnemyData,
		alive_party: Array[CharacterBlock]) -> EnemyAction:
	# Get pool — pattern for bosses, action_pool for regular
	var pool: Array[EnemyAction] = []
	if enemy.is_boss and not enemy.pattern.is_empty():
		var pattern_action = enemy.pattern[enemy.pattern_index % enemy.pattern.size()]
		enemy.pattern_index += 1
		if _condition_met(pattern_action.condition, enemy, alive_party):
			return pattern_action
		# Pattern condition not met — fall through to action pool

	pool = enemy.action_pool

	# Group actions by condition priority
	var best_priority: int = -1
	var candidates: Array[EnemyAction] = []

	for action in pool:
		if not _condition_met(action.condition, enemy, alive_party):
			continue
		var priority = CONDITION_PRIORITY.find(action.condition)
		if priority > best_priority:
			best_priority = priority
			candidates.clear()
			candidates.append(action)
		elif priority == best_priority:
			candidates.append(action)

	if candidates.is_empty():
		return null

	# Among candidates with same priority pick by weight
	return _weighted_pick(candidates)

func _condition_met(
		condition: EnemyAction.Condition,
		enemy: EnemyData,
		alive_party: Array[CharacterBlock]) -> bool:
	var hp_percent = float(enemy.current_hp) / float(enemy.max_hp)
	match condition:
		EnemyAction.Condition.ALWAYS:
			return true
		EnemyAction.Condition.FIRST_TURN_ONLY:
			return turn_number == 1
		EnemyAction.Condition.ALLY_ENEMY_DEAD:
			return enemy_died_this_round
		EnemyAction.Condition.PARTY_HAS_BUFFS:
			return _party_has_buffs(alive_party)
		EnemyAction.Condition.SELF_LOW_HP:
			return hp_percent <= 0.5
		EnemyAction.Condition.SELF_CRITICAL_HP:
			return hp_percent <= 0.25
	return false

func _party_has_buffs(alive_party: Array[CharacterBlock]) -> bool:
	for block in alive_party:
		if not block.character_data.active_effects.is_empty():
			return true
	return false

func _weighted_pick(actions: Array[EnemyAction]) -> EnemyAction:
	var total_weight: float = 0.0
	for action in actions:
		total_weight += action.weight
	var roll = randf() * total_weight
	var cumulative: float = 0.0
	for action in actions:
		cumulative += action.weight
		if roll <= cumulative:
			return action
	return actions[-1]

func _select_target(
		action: EnemyAction,
		alive_party: Array[CharacterBlock],
		_enemy: EnemyData) -> CharacterBlock:
	if alive_party.is_empty():
		return null

	match action.target_strategy:
		EnemyAction.TargetStrategy.SELF:
			return null  # signals TurnManager to target self
		EnemyAction.TargetStrategy.RANDOM_ALIVE:
			return alive_party[randi() % alive_party.size()]
		EnemyAction.TargetStrategy.LOWEST_HP:
			return _get_lowest_hp(alive_party)
		EnemyAction.TargetStrategy.HIGHEST_HP:
			return _get_highest_hp(alive_party)
		EnemyAction.TargetStrategy.LOWEST_HP_PERCENT:
			return _get_lowest_hp_percent(alive_party)
		EnemyAction.TargetStrategy.HIGHEST_HP_PERCENT:
			return _get_highest_hp_percent(alive_party)
		EnemyAction.TargetStrategy.HIGHEST_ATK:
			return _get_highest_stat(alive_party, "atk")
		EnemyAction.TargetStrategy.HIGHEST_MAG:
			return _get_highest_stat(alive_party, "mag")
	return alive_party[randi() % alive_party.size()]

func _get_lowest_hp(party: Array[CharacterBlock]) -> CharacterBlock:
	var lowest = party[0]
	for block in party:
		if block.character_data.current_hp < lowest.character_data.current_hp:
			lowest = block
	return lowest

func _get_highest_hp(party: Array[CharacterBlock]) -> CharacterBlock:
	var highest = party[0]
	for block in party:
		if block.character_data.current_hp > highest.character_data.current_hp:
			highest = block
	return highest

func _get_lowest_hp_percent(party: Array[CharacterBlock]) -> CharacterBlock:
	var lowest = party[0]
	var lowest_pct = float(lowest.character_data.current_hp) / float(lowest.character_data.max_hp)
	for block in party:
		var pct = float(block.character_data.current_hp) / float(block.character_data.max_hp)
		if pct < lowest_pct:
			lowest_pct = pct
			lowest = block
	return lowest

func _get_highest_hp_percent(party: Array[CharacterBlock]) -> CharacterBlock:
	var highest = party[0]
	var highest_pct = float(highest.character_data.current_hp) / float(highest.character_data.max_hp)
	for block in party:
		var pct = float(block.character_data.current_hp) / float(block.character_data.max_hp)
		if pct > highest_pct:
			highest_pct = pct
			highest = block
	return highest

func _get_highest_stat(party: Array[CharacterBlock], stat: String) -> CharacterBlock:
	var highest = party[0]
	for block in party:
		if block.character_data.get(stat) > highest.character_data.get(stat):
			highest = block
	return highest
