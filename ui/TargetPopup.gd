extends Panel
class_name TargetPopup

signal target_selected(character: CharacterData)
signal back_pressed

@onready var back_btn = $VBoxContainer/HeaderRow/BackBtn
@onready var target_grid = $VBoxContainer/TargetGrid

var target_blocks: Array[TargetBlock] = []

func _ready() -> void:
	back_btn.pressed.connect(func(): back_pressed.emit())
	target_grid.columns = 2

func setup(blocks: Array[CharacterBlock], ability_type: String) -> void:
	# Clear existing
	for child in target_grid.get_children():
		child.queue_free()
	target_blocks.clear()

	var block_scene = preload("res://ui/TargetBlock.tscn")
	for block in blocks:
		var target = block_scene.instantiate()
		target_grid.add_child(target)
		var valid = _is_valid_target(block.character_data, ability_type)
		target.setup(block.character_data, valid)
		target.target_selected.connect(_on_target_selected)
		target_blocks.append(target)

func _is_valid_target(data: CharacterData, ability_type: String) -> bool:
	match ability_type:
		"HEALING":
			return data.is_alive and data.current_hp < data.max_hp
		"REVIVE":
			return not data.is_alive
		"BUFF":
			return data.is_alive
		"COVER":
			return data.is_alive
		"HEALING_MP":
			return data.is_alive and data.current_mp < data.max_mp
		_:
			return data.is_alive

func _on_target_selected(target: TargetBlock) -> void:
	target_selected.emit(target.character_data)
