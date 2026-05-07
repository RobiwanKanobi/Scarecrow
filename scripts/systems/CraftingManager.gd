extends Node

var recipes: Array = []

func _ready() -> void:
	add_to_group("crafting_manager")
	_setup_recipes()

func _setup_recipes() -> void:
	recipes = [
		{
			"id": "straw_patch",
			"display_name": "Straw Patch",
			"description": "Repair yourself. Restores 30 health.",
			"cost": {"straw": 3, "cloth": 1},
			"creates_placeable": false,
			"heal_amount": 30,
		},
		{
			"id": "torch",
			"display_name": "Torch",
			"description": "Light source. Place it to protect from night.",
			"cost": {"stick": 2, "straw": 2},
			"creates_placeable": true,
			"placeable_scene": "res://scenes/placeables/LightSource.tscn",
		},
		{
			"id": "crow_trap",
			"display_name": "Crow Trap",
			"description": "Traps and destroys crows. Has 1 use.",
			"cost": {"stick": 2, "straw": 2},
			"creates_placeable": true,
			"placeable_scene": "res://scenes/placeables/CrowTrap.tscn",
		},
		{
			"id": "crop_plot",
			"display_name": "Crop Plot",
			"description": "Grows crops. Crows may attack it at night.",
			"cost": {"straw": 2, "stone": 2, "seed": 1},
			"creates_placeable": true,
			"placeable_scene": "res://scenes/placeables/CropPlot.tscn",
		},
		{
			"id": "firepit",
			"display_name": "Scare Lantern",
			"description": "Strong light source. Protects a wide area.",
			"cost": {"stone": 4, "stick": 3, "straw": 2},
			"creates_placeable": true,
			"placeable_scene": "res://scenes/placeables/LightSource.tscn",
		},
	]

func can_craft(recipe_id: String) -> bool:
	var inventory := _get_inventory()
	if inventory == null:
		return false
	for recipe: Dictionary in recipes:
		if recipe["id"] == recipe_id:
			return inventory.has_items(recipe["cost"])
	return false

func craft(recipe_id: String) -> bool:
	var inventory := _get_inventory()
	if inventory == null:
		return false

	for recipe: Dictionary in recipes:
		if recipe["id"] != recipe_id:
			continue

		if not inventory.has_items(recipe["cost"]):
			GameEvents.message_requested.emit("Not enough materials!")
			return false

		if recipe["creates_placeable"]:
			var placement := get_tree().get_first_node_in_group("placement_manager")
			if placement:
				placement.begin_placement(recipe["placeable_scene"], recipe["cost"])
			return true
		else:
			inventory.remove_items(recipe["cost"])
			if recipe["id"] == "straw_patch":
				var player := get_tree().get_first_node_in_group("player")
				if player:
					var stats := player.get_node_or_null("PlayerStats")
					if stats:
						stats.heal(recipe["heal_amount"])
						GameEvents.message_requested.emit("Used Straw Patch — restored 30 health.")
			return true

	return false

func _get_inventory() -> Node:
	return get_tree().get_first_node_in_group("inventory_manager")
