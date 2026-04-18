extends Node
class_name PlaceholderData

static func create_abilities() -> Array[AbilityData]:
	var abilities: Array[AbilityData] = []

	var slash = AbilityData.new()
	slash.ability_name = "Double Slash"
	slash.description = "Strikes enemy 4 times"
	slash.mp_cost = 10
	slash.hits = 4
	slash.power = 120
	slash.ability_type = AbilityData.AbilityType.OFFENSIVE
	slash.damage_type = AbilityData.DamageType.PHYSICAL
	slash.target_type = AbilityData.TargetType.SINGLE_ENEMY
	abilities.append(slash)

	var fira = AbilityData.new()
	fira.ability_name = "Fira"
	fira.description = "Strikes enemy with fire 3 times"
	fira.mp_cost = 15
	fira.ability_type = AbilityData.AbilityType.OFFENSIVE
	fira.damage_type = AbilityData.DamageType.MAGICAL
	fira.element = CharacterData.Element.FIRE
	fira.power = 180
	fira.hits = 3
	fira.target_type = AbilityData.TargetType.SINGLE_ENEMY
	abilities.append(fira)

	var heal = AbilityData.new()
	heal.ability_name = "Cure"
	heal.description = "Restores 30% HP to one ally"
	heal.mp_cost = 8
	heal.power = 0
	heal.ability_type = AbilityData.AbilityType.HEALING
	heal.damage_type = AbilityData.DamageType.NONE
	heal.target_type = AbilityData.TargetType.SINGLE_ALLY
	heal.heal_percent = 0.3
	abilities.append(heal)

	var revive = AbilityData.new()
	revive.ability_name = "Raise"
	revive.description = "Revives a fallen ally with 50% HP"
	revive.mp_cost = 20
	revive.ability_type = AbilityData.AbilityType.REVIVE
	revive.damage_type = AbilityData.DamageType.NONE
	revive.target_type = AbilityData.TargetType.SINGLE_ALLY
	revive.heal_percent = 0.5
	abilities.append(revive)

	var double_cast = AbilityData.new()
	double_cast.ability_name = "Double Cast"
	double_cast.description = "Cast two magic abilities"
	double_cast.mp_cost = 0
	double_cast.ability_type = AbilityData.AbilityType.OFFENSIVE
	double_cast.damage_type = AbilityData.DamageType.NONE
	double_cast.is_multi_cast = true
	double_cast.cast_count = 2
	double_cast.cast_restriction = AbilityData.CastRestriction.NONE
	abilities.append(double_cast)

	var cover = AbilityData.new()
	cover.ability_name = "Cover"
	cover.description = "Take damage for one ally for 2 turns"
	cover.mp_cost = 10
	cover.ability_type = AbilityData.AbilityType.COVER
	cover.damage_type = AbilityData.DamageType.NONE
	cover.target_type = AbilityData.TargetType.SINGLE_ALLY
	cover.cover_turns = 2
	cover.cover_damage_reduction = 0.3
	cover.cover_party = false
	abilities.append(cover)

	var provoke = AbilityData.new()
	provoke.ability_name = "Provoke"
	provoke.description = "Force one enemy to target you for 2 turns"
	provoke.mp_cost = 8
	provoke.ability_type = AbilityData.AbilityType.BUFF
	provoke.damage_type = AbilityData.DamageType.NONE
	provoke.target_type = AbilityData.TargetType.SINGLE_ENEMY
	provoke.buff_turns = 2
	provoke.applies_taunt = true
	abilities.append(provoke)
	
	var barrier = AbilityData.new()
	barrier.ability_name = "Barrier"
	barrier.description = "Creates a shield worth 30% max HP for 2 turns"
	barrier.mp_cost = 15
	barrier.ability_type = AbilityData.AbilityType.BUFF
	barrier.damage_type = AbilityData.DamageType.NONE
	barrier.target_type = AbilityData.TargetType.SINGLE_ALLY
	barrier.buff_turns = 2
	barrier.shield_percent = 0.3
	barrier.shield_turns = 2
	abilities.append(barrier)

	var armbreak = AbilityData.new()
	armbreak.ability_name = "Armor Break"
	armbreak.description = "Lowers Defense of one foe"
	armbreak.ability_type = AbilityData.AbilityType.OFFENSIVE
	armbreak.damage_type = AbilityData.DamageType.PHYSICAL
	armbreak.target_type = AbilityData.TargetType.SINGLE_ENEMY
	armbreak.mp_cost = 35
	armbreak.power = 100
	armbreak.hits = 1
	armbreak.mod_def = -0.3
	armbreak.buff_turns = 3
	abilities.append(armbreak)
	
	var esuna = AbilityData.new()
	esuna.ability_name = "Esuna"
	esuna.description = "Removes Sleep and Zombie from one ally"
	esuna.mp_cost = 12
	esuna.ability_type = AbilityData.AbilityType.BUFF
	esuna.damage_type = AbilityData.DamageType.NONE
	esuna.target_type = AbilityData.TargetType.SINGLE_ALLY
	esuna.buff_turns = 0
	esuna.removes_statuses = true
	esuna.status_removals = [
			StatusEffect.Type.SLEEP,
				StatusEffect.Type.ZOMBIE] 

	return abilities

static func create_party() -> Array[CharacterData]:
	var party: Array[CharacterData] = []
	var names = ["Lenna", "Reina", "Fina", "Lid", "Zargabaath", "Rain"]
	for char_name in names:
		var data = CharacterData.new()
		data.char_name = char_name
		data.max_hp = 1000
		data.current_hp = randi_range(400, 1000)
		data.max_mp = 100
		data.current_mp = randi_range(20, 100)
		data.atk = randi_range(80, 150)
		data.def = randi_range(30, 70)
		data.mag = randi_range(80, 150)
		data.spr = randi_range(30, 70)
		data.abilities = create_abilities()
		party.append(data)
	return party

static func create_enemies() -> Array[EnemyData]:
	var enemies: Array[EnemyData] = []
	var enemy_configs = [
		{"name": "Goblin", "type": EnemyData.EnemyType.BEAST,
		 "extra_action": _create_poison_ability()},
		{"name": "Orc", "type": EnemyData.EnemyType.BEAST,
		 "extra_action": _create_zombie_ability()},
		{"name": "Troll", "type": EnemyData.EnemyType.BEAST,
		 "extra_action": _create_sleep_ability()}
	]
	for config in enemy_configs:
		var data = EnemyData.new()
		data.enemy_name = config["name"]
		data.enemy_type = config["type"]
		data.max_hp = randi_range(3000, 8000)
		data.current_hp = data.max_hp
		data.atk = randi_range(80, 120)
		data.def = randi_range(30, 60)
		data.mag = randi_range(80, 120)
		data.spr = randi_range(30, 60)
		print(data.enemy_name, ", Def: ", data.def)
		# Basic attack
		var basic_attack = EnemyAction.new()
		basic_attack.action_name = "Attack"
		basic_attack.ability = null
		basic_attack.weight = 0.1
		basic_attack.condition = EnemyAction.Condition.ALWAYS
		basic_attack.target_strategy = EnemyAction.TargetStrategy.LOWEST_HP_PERCENT
		data.action_pool.append(basic_attack)
		# Special action
		var special = EnemyAction.new()
		special.action_name = config["extra_action"].ability_name
		special.ability = config["extra_action"]
		special.weight = 0.9
		special.condition = EnemyAction.Condition.ALWAYS
		special.target_strategy = EnemyAction.TargetStrategy.RANDOM_ALIVE
		data.action_pool.append(special)
		enemies.append(data)
	return enemies

static func create_inventory() -> void:
	var potion = ItemData.new()
	potion.item_name = "Potion"
	potion.quantity = 5
	potion.item_type = ItemData.ItemType.HEALING_HP
	potion.target_type = ItemData.TargetType.SINGLE_ALLY
	potion.heal_amount = 500
	potion.description = "Restores 500 HP to one ally"
	GameState.add_item(potion)

	var ether = ItemData.new()
	ether.item_name = "Ether"
	ether.quantity = 3
	ether.item_type = ItemData.ItemType.HEALING_MP
	ether.target_type = ItemData.TargetType.SINGLE_ALLY
	ether.heal_amount = 50
	ether.description = "Restores 50 MP to one ally"
	GameState.add_item(ether)

	var grenade = ItemData.new()
	grenade.item_name = "Grenade"
	grenade.quantity = 2
	grenade.item_type = ItemData.ItemType.OFFENSIVE
	grenade.target_type = ItemData.TargetType.SINGLE_ENEMY
	grenade.power = 300
	grenade.description = "Deals 300 damage to one enemy"
	GameState.add_item(grenade)

static func _create_poison_ability() -> AbilityData:
	var ability = AbilityData.new()
	ability.ability_name = "Poison Sting"
	ability.ability_type = AbilityData.AbilityType.OFFENSIVE
	ability.damage_type = AbilityData.DamageType.PHYSICAL
	ability.power = 80
	ability.hits = 1
	ability.inflicts_status = true
	ability.status_type = StatusEffect.Type.POISON
	ability.status_duration = 3
	ability.status_chance = 0.7
	return ability

static func _create_sleep_ability() -> AbilityData:
	var ability = AbilityData.new()
	ability.ability_name = "Sleep Spore"
	ability.ability_type = AbilityData.AbilityType.OFFENSIVE
	ability.damage_type = AbilityData.DamageType.NONE
	ability.power = 0
	ability.hits = 1
	ability.inflicts_status = true
	ability.status_type = StatusEffect.Type.SLEEP
	ability.status_duration = 3
	ability.status_chance = 0.6
	return ability

static func _create_def_down_ability() -> AbilityData:
	var ability = AbilityData.new()
	ability.ability_name = "Armor Break"
	ability.ability_type = AbilityData.AbilityType.OFFENSIVE
	ability.damage_type = AbilityData.DamageType.PHYSICAL
	ability.power = 100
	ability.hits = 1
	ability.mod_def = -0.3
	ability.buff_turns = 3
	return ability

static func _create_zombie_ability() -> AbilityData:
	var ability = AbilityData.new()
	ability.ability_name = "Zombiefication"
	ability.ability_type = AbilityData.AbilityType.OFFENSIVE
	ability.damage_type = AbilityData.DamageType.PHYSICAL
	ability.power = 100
	ability.hits = 1
	ability.inflicts_status = true
	ability.status_type = StatusEffect.Type.ZOMBIE
	ability.status_duration = 99
	ability.buff_turns = 3
	return ability
