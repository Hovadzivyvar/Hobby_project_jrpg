# BattleScene.gd
extends Node2D

enum Phase { PLAYER, ENEMY }
var current_phase: Phase = Phase.PLAYER

var party: Array[CharacterData] = []
var blocks: Array[CharacterBlock] = []

var enemies: Array[EnemyData] = []
var enemy_blocks: Array[EnemyBlock] = []
var selected_enemy: EnemyBlock = null

var chain_label_timer: float = 0.0
var chain_label_visible: bool = false
const CHAIN_LABEL_TIMEOUT: float = 1.5
var multi_cast_pending_targets: Array = []
var current_multi_cast_ability_index: int = 0

@onready var top_area = $BattleUI/MainLayout/TopArea
@onready var chain_manager = $ChainManager

@onready var character_grid = $BattleUI/MainLayout/BottomPanel/CharacterGrid
@onready var action_menu = $BattleUI/MainLayout/BottomPanel/ActionMenu
@onready var chain_label = $BattleUI/MainLayout/TopArea/ChainLabel

@onready var enemy_container = $BattleUI/MainLayout/TopArea/SectionsRow/EnemySection/EnemyContainer
@onready var enemy_hp_bar = $BattleUI/MainLayout/TopArea/EnemyHPBar/HPBar
@onready var enemy_hp_label = $BattleUI/MainLayout/TopArea/EnemyHPBar/HPLabel
@onready var damage_calculator = $DamageCalculator
@onready var turn_manager = $TurnManager
@onready var ability_menu = $BattleUI/MainLayout/BottomPanel/AbilityMenu
@onready var item_menu = $BattleUI/MainLayout/BottomPanel/ItemMenu
@onready var bottom_panel = $BattleUI/MainLayout/BottomPanel
@onready var target_popup = $BattleUI/MainLayout/BottomPanel/TargetPopup
@onready var enemy_ai = $EnemyAI
@onready var action_executor = $ActionExecutor
@onready var battle_menu_manager = $BattleMenuManager
@onready var status_manager = $StatusManager
@onready var enemy_action_label = $BattleUI/MainLayout/TopArea/EnemyActionLabel

var damage_label_scene = preload("res://ui/DamageLabel.tscn")
@onready var battle_ui = $BattleUI  # your CanvasLayer

func _ready() -> void:
	print("READY START")
	action_menu.hide()
	ability_menu.hide()
	item_menu.hide()
	target_popup.hide()
	chain_manager.chain_updated.connect(_update_chain_label)
	chain_manager.chain_reset.connect(_on_chain_reset)
	_setup_party()
	_setup_enemies()
	turn_manager.setup(blocks, enemy_blocks, damage_calculator, enemy_ai, status_manager)
	turn_manager.round_reset.connect(_on_round_reset)
	turn_manager.party_defeated.connect(_on_party_defeated)
	turn_manager.enemy_turn_started.connect(_on_enemy_turn_started)
	turn_manager.character_damaged.connect(_spawn_character_damage_number)
	turn_manager.player_turn_started.connect(_on_player_turn_started)
	action_executor.setup(
		blocks, enemy_blocks, damage_calculator, chain_manager,
		func(): return selected_enemy, status_manager )
	action_executor.enemy_defeated.connect(_on_enemy_defeated)
	action_executor.damage_spawned.connect(_spawn_damage_number)
	action_executor.enemy_hp_updated.connect(_update_enemy_hp_bar)
	action_executor.character_refreshed.connect(_refresh_character_block)
	battle_menu_manager.setup(
		blocks, enemy_blocks,
		action_menu, ability_menu, item_menu, target_popup,
		func(): return selected_enemy)
	bottom_panel.gui_input.connect(battle_menu_manager._on_bottom_panel_input)
	status_manager.setup(blocks)
	status_manager.poison_damage.connect(_spawn_character_damage_number)
	status_manager.party_fully_petrified.connect(_on_party_defeated)
	status_manager.confuse_action.connect(_on_confuse_action)
	status_manager.block_status_changed.connect(_on_block_status_changed)
	turn_manager.enemy_action_used.connect(_show_enemy_action)
	_setup_inventory()

func _setup_party() -> void:
	party = PlaceholderData.create_party()
	var block_scene = preload("res://ui/CharacterBlock.tscn")
	for data in party:
		var block: CharacterBlock = block_scene.instantiate()
		character_grid.add_child(block)
		block.setup(data)
		if not block.block_tapped.is_connected(_on_block_tapped):
			block.block_tapped.connect(_on_block_tapped)
		if not block.block_long_pressed.is_connected(_on_block_long_pressed):
			block.block_long_pressed.connect(_on_block_long_pressed)
		blocks.append(block)


func _on_block_long_pressed(block: CharacterBlock) -> void:
	if current_phase != Phase.PLAYER:
		return
	if not block.character_data.is_alive:
		return
	battle_menu_manager.open_action_menu(block)

func _on_block_tapped(block: CharacterBlock) -> void:
	if current_phase != Phase.PLAYER:
		return
	if not block.chosen_action or block.has_fired:
		return
	if not block.character_data.is_alive:
		return
	block.set_fired()
	match block.chosen_action:
		"Defense":
			var defense_ability = action_executor.get_defense_ability()
			damage_calculator.apply_effect_to_character(
				defense_ability, block.character_data)
			print(block.character_data.char_name, " takes defensive stance")
			turn_manager.register_fired()
		"Attack":
			if not selected_enemy:
				turn_manager.register_fired()
				return
			var basic = action_executor.get_basic_attack_ability(block.character_data)
			await action_executor.execute_hits_with_ability(block, basic)
			turn_manager.register_fired()
		_:
			if block.pending_abilities.is_empty() and block.pending_item == null:
				turn_manager.register_fired()
				return
			await action_executor.execute_block_actions(block)
			turn_manager.register_fired()
	
func _setup_enemies() -> void:
	var enemy_data_list = PlaceholderData.create_enemies()
	var enemy_scene = preload("res://ui/EnemyBlock.tscn")
	for data in enemy_data_list:
		enemies.append(data)
		var block: EnemyBlock = enemy_scene.instantiate()
		enemy_container.add_child(block)
		block.setup(data)
		block.enemy_tapped.connect(_on_enemy_tapped)
		enemy_blocks.append(block)
	call_deferred("_select_enemy", enemy_blocks[0])

																										
func _on_enemy_tapped(block: EnemyBlock) -> void:
	_select_enemy(block)
																												
func _select_enemy(block: EnemyBlock) -> void:
	if selected_enemy:
		selected_enemy.set_selected(false)
	selected_enemy = block
	selected_enemy.set_selected(true)
	_update_enemy_hp_bar()
	# Show this enemy's chain if it has one
	var chain = chain_manager.get_enemy_chain(block)
	if chain["count"] > 0:
		_update_chain_label(chain)
	else:
		_on_chain_reset()
			
func _update_enemy_hp_bar() -> void:
	var data = selected_enemy.enemy_data
	enemy_hp_bar.max_value = data.max_hp
	enemy_hp_bar.value = data.current_hp
	enemy_hp_label.text = "%s   HP: %d / %d" % [data.enemy_name, data.current_hp, data.max_hp]
	
	
func _apply_damage(enemy_block: EnemyBlock, damage: int, multiplier: float = 1.0) -> void:
	enemy_block.enemy_data.current_hp -= damage
	enemy_block.enemy_data.current_hp = max(0, enemy_block.enemy_data.current_hp)
	_update_enemy_hp_bar()
	_spawn_damage_number(enemy_block, damage, multiplier)
	if enemy_block.enemy_data.current_hp <= 0:
		_on_enemy_defeated(enemy_block)

func _on_enemy_defeated(enemy_block: EnemyBlock) -> void:
	chain_manager.clear_enemy(enemy_block)
	enemy_ai.notify_enemy_died()
	print(enemy_block.enemy_data.enemy_name, " defeated!")
	enemy_blocks.erase(enemy_block)
	enemies.erase(enemy_block.enemy_data)
	# Null selected_enemy BEFORE freeing
	if selected_enemy == enemy_block:
		selected_enemy = null
	enemy_block.queue_free()
	if enemy_blocks.is_empty():
		print("All enemies defeated! Battle won!")
		return
	_select_enemy(enemy_blocks[0])
	
func _spawn_damage_number(enemy_block: EnemyBlock, damage: int, multiplier: float = 1.0) -> void:
	var popup = damage_label_scene.instantiate()
	# Add to scene so it renders on top of everything
	battle_ui.add_child(popup)
	# Position at enemy block's screen position, centered
	var enemy_center = enemy_block.global_position + enemy_block.size / 2
	popup.position = enemy_center + Vector2(randf_range(-30, 30), randf_range(-20, 20))
	var color: Color
	if multiplier >= 2.0:
		color = Color.ORANGE
	elif multiplier >= 1.5:
		color = Color.YELLOW
	else:
		color = Color.WHITE
													
	popup.setup(damage)

func _process(delta: float) -> void:
	if chain_label_visible:
		chain_label_timer -= delta
		if chain_label_timer <= 0:
			chain_label_visible = false
			var tween = create_tween()
			tween.tween_property(chain_label, "modulate:a", 0.0, 0.4)
			tween.tween_callback(chain_label.hide )
	

func _spawn_character_damage_number(block: CharacterBlock, damage: int) -> void:
	var popup = damage_label_scene.instantiate()
	battle_ui.add_child(popup)
	var block_center = block.global_position + block.size / 2
	popup.position = block_center + Vector2(randf_range(-20, 20), randf_range(-10, 10))
	popup.setup(damage, Color.RED)
	
	
func _update_chain_label(chain: Dictionary) -> void:
	chain_label.show()
	chain_label.modulate.a = 1.0
	chain_label.text = "CHAIN x%d\n+%d dmg" % [chain["count"], chain["total"]]
	chain_label_timer = CHAIN_LABEL_TIMEOUT
	chain_label_visible = true

func _on_chain_reset() -> void:
	chain_label.hide()
	chain_label_visible = false
	chain_label_timer = 0.0
	
func _on_enemy_turn_started() -> void:
	current_phase = Phase.ENEMY

func _on_player_turn_started() -> void:
	current_phase = Phase.PLAYER

func _on_round_reset() -> void:
	for block in blocks:
		block.character_data.tick_effects()
		block.character_data.tick_cooldowns()
		block.character_data.tick_cover_and_taunt()
		block.update_hp()
		block.update_mp()
	for enemy_block in enemy_blocks:
		enemy_block.enemy_data.tick_effects()
		enemy_block.enemy_data.tick_taunt()
	chain_manager.reset_all()
	chain_label.hide()
	chain_label_visible = false
	chain_label_timer = 0.0
	print("New round begins")

func _on_party_defeated() -> void:
	current_phase = Phase.ENEMY
	print("Game over!")
	
func _setup_inventory() -> void:
	PlaceholderData.create_inventory()

func _refresh_character_block(target: CharacterData) -> void:
	action_executor.refresh_character_block(target)

func _on_confuse_action(block: CharacterBlock) -> void:
	if not block.character_data.is_alive:
		return
	# Pick random target including self
	var all_targets = blocks.filter(func(b): return b.character_data.is_alive)
	if all_targets.is_empty():
		return
	var target = all_targets[randi() % all_targets.size()]
	var _basic = action_executor.get_basic_attack_ability(block.character_data)
	# Confused attack hits ally — use character damage path
	if target == block or blocks.has(target):
		var damage = damage_calculator.calculate_enemy_damage(
			null, target.character_data,
			AbilityData.DamageType.PHYSICAL,
			CharacterData.Element.NONE)
		damage_calculator.apply_damage_to_character(damage, target.character_data)
		target.update_hp()
		_spawn_character_damage_number(target, damage)
		print(block.character_data.char_name, " confused, attacks ",
			target.character_data.char_name, " for ", damage)

func _on_block_status_changed(block: CharacterBlock) -> void:
	var cannot_act = not status_manager.can_act(block.character_data)
	if cannot_act:
		block.set_incapacitated()
	else:
		block.set_ready()

func _show_enemy_action(enemy_name: String, action_name: String) -> void:
	enemy_action_label.text = "%s uses %s" % [enemy_name, action_name]
	enemy_action_label.show()
	enemy_action_label.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(enemy_action_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(enemy_action_label.hide)
