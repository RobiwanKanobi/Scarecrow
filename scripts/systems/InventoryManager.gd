extends Node

signal inventory_changed

var items: Dictionary = {
	"straw": 0,
	"stick": 0,
	"cloth": 0,
	"stone": 0,
	"seed": 0,
	"berry": 0,
}

func _ready() -> void:
	add_to_group("inventory_manager")

func add_item(item_id: String, amount: int) -> void:
	if items.has(item_id):
		items[item_id] += amount
	else:
		items[item_id] = amount
	inventory_changed.emit()
	GameEvents.item_collected.emit(item_id, amount)

func remove_item(item_id: String, amount: int) -> bool:
	if not has_item(item_id, amount):
		return false
	items[item_id] -= amount
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int) -> bool:
	return items.get(item_id, 0) >= amount

func has_items(cost: Dictionary) -> bool:
	for item_id: String in cost:
		if not has_item(item_id, cost[item_id]):
			return false
	return true

func remove_items(cost: Dictionary) -> bool:
	if not has_items(cost):
		return false
	for item_id: String in cost:
		items[item_id] -= cost[item_id]
	inventory_changed.emit()
	return true

func get_item_count(item_id: String) -> int:
	return items.get(item_id, 0)
