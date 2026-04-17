extends Node2D
class_name DamageLabel

@onready var label = $Label

func setup(damage: int, color: Color = Color.WHITE) -> void:
	label.text = str(damage)
	label.modulate = color
	# Center the label on the spawn point
	await get_tree().process_frame
	label.pivot_offset = label.size / 2
	_animate()

func _animate() -> void:
	var tween = create_tween()
	# Float upward
	tween.tween_property(self, "position:y", position.y - 80, 0.8)
	# Fade out in the last portion
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	# Remove when done
	tween.tween_callback(queue_free)
