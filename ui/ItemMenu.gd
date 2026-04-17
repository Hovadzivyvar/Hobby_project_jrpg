
extends Panel
class_name ItemMenu

signal item_chosen(item: ItemData)
signal back_pressed

@onready var back_btn = $VBoxContainer/HeaderRow/BackBtn
@onready var item_list = $VBoxContainer/ScrollContainer/ItemList

func _ready() -> void:
	back_btn.pressed.connect(func(): back_pressed.emit())

func setup() -> void:
	_populate_list()

func _populate_list() -> void:
	print("Populating items, count: ", GameState.inventory.size())
	for child in item_list.get_children():
		child.queue_free()
	for item in GameState.inventory:
		if item.quantity <= 0:
			continue
		var btn = Button.new()
		btn.text = "%s x%d\n%s" % [item.item_name, item.quantity, item.description]
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.pressed.connect(_on_item_pressed.bind(item))
		item_list.add_child(btn)

func _on_item_pressed(item: ItemData) -> void:
	item_chosen.emit(item)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			accept_event()
