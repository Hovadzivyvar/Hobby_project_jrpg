# CharacterBlock.gd
extends Panel
class_name CharacterBlock 

signal block_tapped(character_block)
signal block_long_pressed(character_block)

var character_data: CharacterData
var chosen_action: String = ""

const LONG_PRESS_DURATION = 0.4  # seconds, adjust to feel right

var press_time: float = 0.0
var is_pressing: bool = false

var has_fired: bool = false
var pending_abilities: Array[AbilityData] = []
var pending_targets: Array = []  # CharacterData or null per ability
var is_multi_cast_mode: bool = false
var multi_cast_ability: AbilityData = null

var pending_item: ItemData = null
var pending_target: CharacterData = null
var targeted_enemy: EnemyBlock = null

@onready var hp_bar = $VBoxContainer/HPControl/HPBar
@onready var hp_label = $VBoxContainer/HPControl/HPLabel
@onready var mp_bar = $VBoxContainer/MPControl/MPBar
@onready var mp_label = $VBoxContainer/MPControl/MPLabel
@onready var name_label = $VBoxContainer/NameLabel
@onready var action_label = $VBoxContainer/ActionLabel



func setup(data: CharacterData) -> void:
	character_data = data
	name_label.text = data.char_name
	action_label.text = ""
	_update_bars()
					
func _update_bars() -> void:
	hp_bar.max_value = character_data.max_hp
	hp_bar.value = character_data.current_hp
	hp_label.text = "HP: %d" % character_data.current_hp
	mp_bar.max_value = character_data.max_mp
	mp_bar.value = character_data.current_mp
	mp_label.text = "MP: %d" % character_data.current_mp

func set_action(action: String) -> void:
	chosen_action = action
	action_label.text = action

func clear_action() -> void:
	chosen_action = ""
	action_label.text = ""
	pending_abilities.clear()
	pending_targets.clear()
	pending_item = null
	is_multi_cast_mode = false
	multi_cast_ability = null


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_pressing = true
			press_time = 0.0
		else:
			if is_pressing:
				# Finger lifted before long press threshold = tap
				if chosen_action != "" and not has_fired:
					block_tapped.emit(self)
			is_pressing = false
			press_time = 0.0
				
func _process(delta: float) -> void:
	if is_pressing:
		if not character_data.is_alive:
			is_pressing = false
			press_time = 0.0
			return
		press_time += delta
		if press_time >= LONG_PRESS_DURATION:
			is_pressing = false
			press_time = 0.0
			block_long_pressed.emit(self)
			
func set_fired() -> void:
	has_fired = true
	modulate = Color(0.4, 0.4, 0.4)  # darken block visually

func set_defeated() -> void:
	modulate = Color(0.2, 0.2, 0.2)
	character_data.is_alive = false

var status_manager_ref: StatusManager = null

func has_status_incapacity() -> bool:
	if not status_manager_ref:
		return false
	return not status_manager_ref.can_act(character_data)

func reset() -> void:
	has_fired = false
	targeted_enemy = null
	clear_action()
	if character_data.is_alive and not has_status_incapacity():
		modulate = Color(1, 1, 1)
											
@onready var shield_bar = $VBoxContainer/HPControl/ShieldBar

func update_hp() -> void:
	#hp_bar.max_value = character_data.max_hp
	hp_bar.value = character_data.current_hp
	hp_label.text = "HP: %d" % character_data.current_hp
	_update_shield()

func _update_shield() -> void:
	if character_data.current_shield > 0:
		shield_bar.max_value = character_data.max_hp
		shield_bar.value = character_data.current_shield
		shield_bar.show()
		hp_label.text = "HP: %d | Shield: %d" % [
			character_data.current_hp,
			character_data.current_shield]
	else:
		shield_bar.hide()
		hp_label.text = "HP: %d" % character_data.current_hp

func update_mp() -> void:
	mp_bar.value = character_data.current_mp
	mp_label.text = "MP: %d" % character_data.current_mp

func set_incapacitated() -> void:
	modulate = Color(0.5, 0.5, 0.8)  # blue tint for status

func set_ready() -> void:
	if character_data.is_alive and not has_fired:
		modulate = Color(1, 1, 1)
