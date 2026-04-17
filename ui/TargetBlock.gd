extends Panel
class_name TargetBlock

signal target_selected(block: TargetBlock)

var character_data: CharacterData = null
var is_valid_target: bool = false

@onready var name_label = $VBoxContainer/NameLabel
@onready var hp_bar = $VBoxContainer/HPBar
@onready var hp_label = $VBoxContainer/HPBar/HPLabel
@onready var mp_bar = $VBoxContainer/MPBar
@onready var mp_label = $VBoxContainer/MPBar/MPLabel

func _ready() -> void:
	_set_children_mouse_filter(self)

func _set_children_mouse_filter(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
		_set_children_mouse_filter(child)

func setup(data: CharacterData, valid: bool) -> void:
	character_data = data
	is_valid_target = valid
	name_label.text = data.char_name
	hp_bar.max_value = data.max_hp
	hp_bar.value = data.current_hp
	hp_label.text = "HP: %d" % data.current_hp
	mp_bar.max_value = data.max_mp
	mp_bar.value = data.current_mp
	mp_label.text = "MP: %d" % data.current_mp
	if not valid:
		modulate = Color(0.3, 0.3, 0.3)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		modulate = Color(1, 1, 1)
		mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if not is_valid_target:
		return
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			target_selected.emit(self)
