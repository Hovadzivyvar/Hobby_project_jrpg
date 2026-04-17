extends Node
class_name BattleMenuManager

var active_block: CharacterBlock = null
var blocks: Array[CharacterBlock] = []
var enemy_blocks: Array[EnemyBlock] = []

var action_menu: Panel = null
var ability_menu: AbilityMenu = null
var item_menu: ItemMenu = null
var target_popup: Panel = null

#signal block_action_assigned(block: CharacterBlock)
#signal enemy_targeted(enemy_block: EnemyBlock)

var get_selected_enemy: Callable

func setup(
		p_blocks: Array[CharacterBlock],
		p_enemy_blocks: Array[EnemyBlock],
		p_action_menu: Panel,
		p_ability_menu: AbilityMenu,
		p_item_menu: ItemMenu,
		p_target_popup: Panel,
		p_get_selected_enemy: Callable) -> void:
	blocks = p_blocks
	enemy_blocks = p_enemy_blocks
	action_menu = p_action_menu
	ability_menu = p_ability_menu
	item_menu = p_item_menu
	target_popup = p_target_popup
	get_selected_enemy = p_get_selected_enemy
	_connect_signals()

func _connect_signals() -> void:
	action_menu.action_chosen.connect(_on_action_chosen)
	action_menu.ability_requested.connect(_on_ability_requested)
	action_menu.item_requested.connect(_on_item_requested)
	ability_menu.ability_chosen.connect(_on_ability_chosen)
	ability_menu.back_pressed.connect(_on_submenu_back)
	ability_menu.multi_cast_complete.connect(_on_multi_cast_complete)
	ability_menu.target_needed.connect(_on_multi_cast_target_needed)
	item_menu.item_chosen.connect(_on_item_chosen)
	item_menu.back_pressed.connect(_on_submenu_back)
	target_popup.target_selected.connect(_on_target_selected)
	target_popup.back_pressed.connect(_on_target_back)

func open_action_menu(block: CharacterBlock) -> void:
	active_block = block
	action_menu.show()

func close_all_menus() -> void:
	action_menu.hide()
	ability_menu.hide()
	item_menu.hide()
	target_popup.hide()
	active_block = null

func _on_action_chosen(action_name: String) -> void:
	if active_block:
		active_block.set_action(action_name)
		active_block = null

func _on_ability_requested() -> void:
	if not active_block:
		return
	ability_menu.setup(active_block.character_data)
	ability_menu.show()

func _on_item_requested() -> void:
	item_menu.setup()
	item_menu.show()

func _on_submenu_back() -> void:
	ability_menu.hide()
	item_menu.hide()

func _on_ability_chosen(ability: AbilityData) -> void:
	if not active_block:
		return
	if ability.is_multi_cast:
		active_block.is_multi_cast_mode = true
		active_block.multi_cast_ability = ability
		ability_menu.setup(
			active_block.character_data,
			true,
			ability.cast_count,
			ability.cast_restriction)
		return
	active_block.targeted_enemy = get_selected_enemy.call()
	active_block.pending_abilities.append(ability)
	if ability.needs_ally_target():
		var type_str = _get_target_type_string_from_ability(ability)
		target_popup.setup(blocks, type_str)
		ability_menu.hide()
		target_popup.show()
	else:
		active_block.set_action(ability.ability_name)
		ability_menu.hide()
		action_menu.hide()
		active_block = null

func _on_multi_cast_complete() -> void:
	if not active_block:
		return
	var selected = ability_menu.get_selected_abilities()
	for ability in selected:
		active_block.pending_abilities.append(ability)
	active_block.set_action(active_block.multi_cast_ability.ability_name)
	ability_menu.hide()
	action_menu.hide()

func _on_multi_cast_target_needed(ability: AbilityData) -> void:
	var type_str = _get_target_type_string_from_ability(ability)
	target_popup.setup(blocks, type_str)
	ability_menu.hide()
	target_popup.show()

func _on_item_chosen(item: ItemData) -> void:
	if not active_block:
		return
	active_block.pending_item = item
	if item.item_type != ItemData.ItemType.OFFENSIVE:
		var type_str = _get_item_target_type_string(item)
		target_popup.setup(blocks, type_str)
		item_menu.hide()
		target_popup.show()
	else:
		active_block.set_action(item.item_name)
		item_menu.hide()
		action_menu.hide()

func _on_target_selected(character: CharacterData) -> void:
	if not active_block:
		return
	target_popup.hide()
	if active_block.is_multi_cast_mode:
		active_block.pending_targets.append(character)
		ability_menu.show()
		ability_menu.resume_after_target()
		return
	active_block.pending_targets.append(character)
	active_block.set_action(
		active_block.pending_abilities[0].ability_name \
		if active_block.pending_abilities.size() > 0 \
		else active_block.pending_item.item_name)
	action_menu.hide()
	active_block = null

func _on_target_back() -> void:
	target_popup.hide()
	if active_block:
		if not active_block.pending_abilities.is_empty():
			active_block.pending_abilities.pop_back()
			ability_menu.show()
		elif active_block.pending_item:
			active_block.pending_item = null
			item_menu.show()

func _on_bottom_panel_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			if ability_menu.visible or item_menu.visible:
				ability_menu.hide()
				item_menu.hide()
			elif action_menu.visible:
				action_menu.hide()
				active_block = null

func _get_target_type_string_from_ability(ability: AbilityData) -> String:
	match ability.ability_type:
		AbilityData.AbilityType.HEALING:    return "HEALING"
		AbilityData.AbilityType.REVIVE:     return "REVIVE"
		AbilityData.AbilityType.BUFF:       return "BUFF"
		AbilityData.AbilityType.COVER:      return "COVER"
		_:                                  return "HEALING"

func _get_item_target_type_string(item: ItemData) -> String:
	match item.item_type:
		ItemData.ItemType.HEALING_HP:   return "HEALING"
		ItemData.ItemType.HEALING_MP:   return "HEALING_MP"
		ItemData.ItemType.REVIVE:       return "REVIVE"
		_:                              return "HEALING"
