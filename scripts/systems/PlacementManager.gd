extends Node

var _placing: bool = false
var _ghost: MeshInstance3D = null
var _scene_path: String = ""
var _cost: Dictionary = {}
var _camera: Camera3D

func _ready() -> void:
	add_to_group("placement_manager")

func _process(_delta: float) -> void:
	if not _placing or _ghost == null:
		return

	if _camera == null:
		_camera = get_viewport().get_camera_3d()
		if _camera == null:
			return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := _camera.project_ray_origin(mouse_pos)
	var dir := _camera.project_ray_normal(mouse_pos)

	if absf(dir.y) < 0.001:
		return

	var t: float = -from.y / dir.y
	var world_pos := from + dir * t
	world_pos.y = 0.0
	_ghost.global_position = world_pos

func _input(event: InputEvent) -> void:
	if not _placing:
		return

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_confirm_placement()

	if event.is_action_pressed("ui_cancel"):
		cancel_placement()

func begin_placement(scene_path: String, cost: Dictionary) -> void:
	if _placing:
		cancel_placement()

	_scene_path = scene_path
	_cost = cost
	_placing = true
	_camera = null

	_ghost = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 1.0, 1.0)
	_ghost.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 1.0, 0.4, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.material_override = mat
	get_parent().add_child(_ghost)

	GameEvents.message_requested.emit("Click to place — Esc to cancel.")

func _confirm_placement() -> void:
	if not _placing:
		return

	var inventory := get_tree().get_first_node_in_group("inventory_manager")
	if inventory == null or not inventory.has_items(_cost):
		GameEvents.message_requested.emit("Not enough materials!")
		cancel_placement()
		return

	inventory.remove_items(_cost)

	var scene := load(_scene_path) as PackedScene
	if scene:
		var obj := scene.instantiate()
		obj.global_position = _ghost.global_position
		get_parent().add_child(obj)
		GameEvents.message_requested.emit("Placed!")
	else:
		GameEvents.message_requested.emit("Error: could not load scene.")

	_cleanup_ghost()
	_placing = false
	_scene_path = ""
	_cost = {}

func cancel_placement() -> void:
	_cleanup_ghost()
	_placing = false
	_scene_path = ""
	_cost = {}

func _cleanup_ghost() -> void:
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null

func is_placing() -> bool:
	return _placing
