extends Node

signal item_collected(item_id: String, amount: int)
signal player_damaged(amount: float)
signal player_healed(amount: float)
signal player_died
signal day_started(day_count: int)
signal night_started(day_count: int)
signal time_changed(normalized_time: float)
signal message_requested(text: String)
signal enemy_killed
signal crop_destroyed
signal toggle_inventory_requested
signal toggle_crafting_requested
