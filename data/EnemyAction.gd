extends Resource
class_name EnemyAction

enum Condition {
	ALWAYS,             # lowest priority fallback
	FIRST_TURN_ONLY,
	ALLY_ENEMY_DEAD,
	PARTY_HAS_BUFFS,
	SELF_LOW_HP,        # below 50%
	SELF_CRITICAL_HP    # below 25% — highest priority
}

enum TargetStrategy {
	RANDOM_ALIVE,
	LOWEST_HP,
	HIGHEST_HP,
	LOWEST_HP_PERCENT,
	HIGHEST_HP_PERCENT,
	HIGHEST_ATK,
	HIGHEST_MAG,
	SELF
}

@export var action_name: String = "Action"
@export var ability: AbilityData = null  # null = basic attack
@export var weight: float = 1.0
@export var condition: Condition = Condition.ALWAYS
@export var target_strategy: TargetStrategy = TargetStrategy.RANDOM_ALIVE
