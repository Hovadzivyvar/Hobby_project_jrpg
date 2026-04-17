extends Node
class_name ChainManager

signal chain_updated(chain: Dictionary)
signal chain_reset

var enemy_chains: Dictionary = {}
const CHAIN_TIMEOUT: float = 0.2
var chain_timers: Dictionary = {}

func get_chain(enemy_block: EnemyBlock) -> Dictionary:
	if not enemy_chains.has(enemy_block):
		enemy_chains[enemy_block] = {
			"count": 0,
			"last_attacker": null,
			"total": 0
		}
	return enemy_chains[enemy_block]

func register_hit(attacker: CharacterData, enemy_block: EnemyBlock) -> float:
	var chain = get_chain(enemy_block)
	if chain["last_attacker"] == attacker and chain["count"] > 0:
		reset_chain(enemy_block)
		chain = get_chain(enemy_block)
	chain["count"] += 1
	chain["last_attacker"] = attacker
	# Reset timer on each new hit
	chain_timers[enemy_block] = CHAIN_TIMEOUT
	var multiplier = calculate_multiplier(chain["count"])
	chain_updated.emit(chain)
	return multiplier

func calculate_multiplier(count: int) -> float:
	if count <= 1:
		return 1.0
	return min(1.0 + (count - 1) * 0.1, 3.0)

func reset_chain(enemy_block: EnemyBlock) -> void:
	if enemy_chains.has(enemy_block):
		print("Chain reset! Total: ", enemy_chains[enemy_block]["total"])
		enemy_chains.erase(enemy_block)
	if chain_timers.has(enemy_block):
		chain_timers.erase(enemy_block)
	chain_reset.emit()

func add_to_total(enemy_block: EnemyBlock, damage: int) -> void:
	var chain = get_chain(enemy_block)
	chain["total"] += damage

func get_enemy_chain(enemy_block: EnemyBlock) -> Dictionary:
	if enemy_chains.has(enemy_block):
		return enemy_chains[enemy_block]
	return {"count": 0, "last_attacker": null, "total": 0}

func clear_enemy(enemy_block: EnemyBlock) -> void:
	if enemy_chains.has(enemy_block):
		enemy_chains.erase(enemy_block)
	if chain_timers.has(enemy_block):
		chain_timers.erase(enemy_block)

func reset_all() -> void:
	enemy_chains.clear()
	chain_timers.clear()
	chain_reset.emit()
	
func _process(delta: float) -> void:
	for enemy_block in chain_timers.keys():
		chain_timers[enemy_block] -= delta
		if chain_timers[enemy_block] <= 0.0:
			reset_chain(enemy_block)
