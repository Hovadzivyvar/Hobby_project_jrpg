extends Panel
class_name EnemyBlock

signal enemy_tapped(enemy_block)

var enemy_data: EnemyData
var is_selected: bool = false

@onready var name_label = $VBoxContainer/NameLabel
@onready var art_placeholder = $VBoxContainer/ArtPlaceholder

func _ready() -> void:
	_set_children_mouse_filter(self)
		
func _set_children_mouse_filter(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_PASS
			_set_children_mouse_filter(child)

func setup(data: EnemyData) -> void:
	enemy_data = data
	name_label.text = data.enemy_name
	
func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		# Highlight with a bright border tint
		modulate = Color(1.4, 1.4, 0.6)
	else:
		modulate = Color(1, 1, 1)
													
func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		enemy_tapped.emit(self)
