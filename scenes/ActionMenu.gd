# ActionMenu.gd
extends Panel

signal ability_requested
signal item_requested
signal action_chosen(action_name)

@onready var attack_btn = $AttackBtn
@onready var defense_btn = $DefenseBtn
@onready var ability_btn = $AbilityBtn
@onready var item_btn = $ItemBtn

func _ready() -> void:
	attack_btn.pressed.connect(_on_action_pressed.bind("Attack"))
	defense_btn.pressed.connect(_on_action_pressed.bind("Defense"))
	ability_btn.pressed.connect(func(): ability_requested.emit())
	item_btn.pressed.connect(func(): item_requested.emit())

func _on_action_pressed(action_name: String) -> void:
	action_chosen.emit(action_name)
	hide()
	
# Optional: tap outside menu to cancel
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		hide() 
