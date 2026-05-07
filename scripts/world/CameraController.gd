extends Node3D

@export var follow_speed: float = 6.0
@export var camera_offset: Vector3 = Vector3(0.0, 14.0, 9.0)

var _target: Node3D
var _camera: Camera3D

func _ready() -> void:
	_camera = get_node_or_null("Camera3D")
	if _camera:
		_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_camera.size = 20.0
		_camera.position = camera_offset
		_camera.rotation_degrees = Vector3(-55.0, 0.0, 0.0)

func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")

	if _target:
		var desired_pos := _target.global_position
		global_position = global_position.lerp(desired_pos, follow_speed * delta)
