extends CharacterBody3D

enum State { MOVING, ATTACKING, FLEEING, DEAD }

@export var health: float = 20.0
@export var move_speed: float = 3.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.5
@export var attack_range: float = 1.5

var _state: State = State.MOVING
var _target: Node3D = null
var _attack_timer: float = 0.0
var _target_update_timer: float = 0.0
var _visual: MeshInstance3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("enemies")
	_visual = get_node_or_null("Visual")
	_set_color(Color(0.10, 0.08, 0.15))
	# Brief spawn delay before seeking
	_target_update_timer = -0.5

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	match _state:
		State.MOVING:
			_move_toward_target(delta)
		State.ATTACKING:
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)
			_attack_timer += delta
			if _attack_timer >= attack_interval:
				_attack_timer = 0.0
				_do_attack()
		State.FLEEING:
			_flee(delta)

	move_and_slide()

func _process(delta: float) -> void:
	if _state == State.DEAD or _state == State.FLEEING:
		return

	_target_update_timer += delta
	if _target_update_timer >= 1.0:
		_target_update_timer = 0.0
		_find_target()

func _find_target() -> void:
	var crops := get_tree().get_nodes_in_group("crop_plots")
	var best: Node3D = null
	var best_dist: float = INF

	for crop: Node3D in crops:
		if is_instance_valid(crop) and crop.has_method("take_damage"):
			var d: float = global_position.distance_to(crop.global_position)
			if d < best_dist:
				best_dist = d
				best = crop

	if best:
		_target = best
		return

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0] as Node3D

func _move_toward_target(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_find_target()
		if _target == null:
			return

	var dist: float = global_position.distance_to(_target.global_position)
	if dist <= attack_range:
		_state = State.ATTACKING
		_attack_timer = 0.0
		return

	var dir: Vector3 = (_target.global_position - global_position)
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed

func _do_attack() -> void:
	if _target == null or not is_instance_valid(_target):
		_state = State.MOVING
		return

	var dist: float = global_position.distance_to(_target.global_position)
	if dist > attack_range * 1.8:
		_state = State.MOVING
		return

	if _target.is_in_group("player"):
		var stats: Node = _target.get_node_or_null("PlayerStats")
		if stats:
			stats.take_damage(attack_damage)
		GameEvents.message_requested.emit("A crow pecks at you!")
	elif _target.has_method("take_damage"):
		_target.take_damage(attack_damage)

func take_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	if health <= 0.0:
		_die()

func _die() -> void:
	_state = State.DEAD
	GameEvents.enemy_killed.emit()
	queue_free()

func flee() -> void:
	if _state == State.DEAD:
		return
	_state = State.FLEEING

func _flee(delta: float) -> void:
	var dir: Vector3 = global_position
	dir.y = 0.0
	if dir.length() < 0.1:
		dir = Vector3(1.0, 0.0, 0.0)
	dir = dir.normalized()

	velocity.x = dir.x * move_speed * 1.5
	velocity.z = dir.z * move_speed * 1.5

	if not is_on_floor():
		velocity.y -= _gravity * delta

	if global_position.length() > 26.0:
		queue_free()

func _set_color(color: Color) -> void:
	if _visual == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	_visual.material_override = mat
