extends Node

const CROW_SCENE := preload("res://scenes/enemies/Crow.tscn")

var _spawn_offsets: Array[Vector3] = [
	Vector3(18, 0.5, 18),
	Vector3(-18, 0.5, 18),
	Vector3(18, 0.5, -18),
	Vector3(-18, 0.5, -18),
]
var _active_crows: Array = []

func _ready() -> void:
	GameEvents.night_started.connect(_on_night_started)
	GameEvents.day_started.connect(_on_day_started)

func _on_night_started(day_count: int) -> void:
	var count: int = 2 + day_count
	_spawn_crows(count)

func _on_day_started(_day_count: int) -> void:
	for crow in _active_crows:
		if is_instance_valid(crow):
			crow.flee()
	_active_crows.clear()

func _spawn_crows(count: int) -> void:
	for i: int in range(count):
		var spawn_pos := _spawn_offsets[i % _spawn_offsets.size()]
		spawn_pos.x += randf_range(-2.5, 2.5)
		spawn_pos.z += randf_range(-2.5, 2.5)

		var crow := CROW_SCENE.instantiate()
		get_parent().add_child(crow)
		crow.global_position = spawn_pos
		crow.tree_exited.connect(_on_crow_removed.bind(crow))
		_active_crows.append(crow)

func _on_crow_removed(crow: Node) -> void:
	_active_crows.erase(crow)
