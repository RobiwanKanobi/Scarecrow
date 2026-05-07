extends CharacterBody3D

@export var move_speed: float = 5.0

var light_sources_touching: int = 0
var is_in_light: bool:
	get:
		return light_sources_touching > 0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _interaction_area: Area3D

func _ready() -> void:
	add_to_group("player")
	_interaction_area = get_node_or_null("InteractionDetector")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_back")

	var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("toggle_inventory"):
		GameEvents.toggle_inventory_requested.emit()
	elif event.is_action_pressed("toggle_crafting"):
		GameEvents.toggle_crafting_requested.emit()

func _try_interact() -> void:
	if _interaction_area == null:
		return

	var nearest: Node3D = null
	var nearest_dist: float = INF

	for body: Node3D in _interaction_area.get_overlapping_bodies():
		if body != self and body.has_method("interact"):
			var d: float = global_position.distance_to(body.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = body

	for area: Area3D in _interaction_area.get_overlapping_areas():
		if area != _interaction_area and area.has_method("interact"):
			var d: float = global_position.distance_to(area.global_position)
			if d < nearest_dist:
				nearest_dist = d
				nearest = area

	if nearest:
		nearest.interact(self)
