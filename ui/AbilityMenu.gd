extends Panel
class_name AbilityMenu

signal ability_chosen(ability: AbilityData)
signal multi_cast_complete
signal back_pressed
signal target_needed(ability: AbilityData)

var current_character: CharacterData = null
var multi_cast_mode: bool = false
var cast_count: int = 0
var max_casts: int = 0
var selected_abilities: Array[AbilityData] = []
var cast_restriction: AbilityData.CastRestriction = AbilityData.CastRestriction.NONE
var ability_buttons: Dictionary = {}  # AbilityData -> Button

@onready var back_btn = $VBoxContainer/HeaderRow/BackBtn
@onready var mp_label = $VBoxContainer/MPLabel
@onready var ability_list = $VBoxContainer/ScrollContainer/AbilityList

func _ready() -> void:
	back_btn.pressed.connect(func(): back_pressed.emit())

func setup(character: CharacterData, multicast: bool = false,
		max_num: int = 0, restriction: AbilityData.CastRestriction = AbilityData.CastRestriction.NONE) -> void:
	current_character = character
	multi_cast_mode = multicast
	max_casts = max_num
	cast_count = 0
	selected_abilities.clear()
	cast_restriction = restriction
	mp_label.text = "MP: %d / %d" % [character.current_mp, character.max_mp]
	_populate_list()

func _populate_list() -> void:
	for child in ability_list.get_children():
		child.queue_free()
	ability_buttons.clear()

	for ability in current_character.abilities:
		var btn = Button.new()
		btn.text = "%s  (MP: %d)\n%s" % [ability.ability_name, ability.mp_cost, ability.description]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD

		var can_use = _can_select(ability)
		btn.disabled = not can_use
		if not can_use:
			btn.modulate = Color(0.5, 0.5, 0.5)

		btn.pressed.connect(_on_ability_pressed.bind(ability))
		ability_list.add_child(btn)
		ability_buttons[ability] = btn

func _can_select(ability: AbilityData) -> bool:
	# Always grey out multicast abilities in multicast mode
	if multi_cast_mode and ability.is_multi_cast:
		return false
	# Check cast restriction
	if multi_cast_mode:
		match cast_restriction:
			AbilityData.CastRestriction.OFFENSIVE_ONLY:
				if not ability.is_offensive():
					return false
			AbilityData.CastRestriction.HEALING_ONLY:
				if not ability.is_healing():
					return false
			AbilityData.CastRestriction.MAGIC_ONLY:
				if ability.damage_type != AbilityData.DamageType.MAGICAL:
					return false
			AbilityData.CastRestriction.PHYSICAL_ONLY:
				if ability.damage_type != AbilityData.DamageType.PHYSICAL:
					return false
	# Check MP
	if current_character.current_mp < ability.mp_cost:
		return false
	# Check cooldown/once per battle
	if not current_character.can_use_ability(ability):
		return false
	return true

func _on_ability_pressed(ability: AbilityData) -> void:
	if not multi_cast_mode:
		ability_chosen.emit(ability)
		return

	# Multi cast mode
	selected_abilities.append(ability)
	cast_count += 1
	_update_button_border(ability, cast_count)

	# If healing/buff needs target
	if ability.needs_ally_target():
		target_needed.emit(ability)
		return

	# Check if we reached max casts
	if cast_count >= max_casts:
		multi_cast_complete.emit()

func _update_button_border(ability: AbilityData, order: int) -> void:
	if ability_buttons.has(ability):
		var btn = ability_buttons[ability]
		btn.text = "[%d] %s  (MP: %d)\n%s" % [order, ability.ability_name, ability.mp_cost, ability.description]
		btn.modulate = Color(1.0, 0.85, 0.0)  # gold border tint

func resume_after_target() -> void:
	# Called after target selection returns to ability menu
	if cast_count >= max_casts:
		multi_cast_complete.emit()

func get_selected_abilities() -> Array[AbilityData]:
	return selected_abilities

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			accept_event()
