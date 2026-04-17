extends Node

var inventory: Array[ItemData] = []

func add_item(item: ItemData) -> void:
	# Check if item already exists, increase quantity
	for existing in inventory:
		if existing.item_name == item.item_name:
			existing.quantity += item.quantity
			return
	inventory.append(item)

func remove_item(item: ItemData) -> void:
	for existing in inventory:
		if existing.item_name == item.item_name:
			existing.quantity -= 1
			if existing.quantity <= 0:
				inventory.erase(existing)
			return

func has_item(item_name: String) -> bool:
	for item in inventory:
		if item.item_name == item_name and item.quantity > 0:
			return true
	return false

func get_item(item_name: String) -> ItemData:
	for item in inventory:
		if item.item_name == item_name:
			return item
	return null
