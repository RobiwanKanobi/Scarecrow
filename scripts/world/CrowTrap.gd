extends Area3D

@export var damage: float = 999.0
@export var uses: int = 1

var _uses_remaining: int = 1
var _visual: MeshInstance3D

func _ready() -> void:
	_uses_remaining = uses
	_visual = get_node_or_null("Visual")
	add_to_group("placeables")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _uses_remaining <= 0:
		return
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_uses_remaining -= 1
		GameEvents.message_requested.emit("Crow trap triggered!")
		if _uses_remaining <= 0:
			_break_trap()

func _break_trap() -> void:
	if _visual:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.15, 0.08)
		_visual.material_override = mat
	get_tree().create_timer(2.0).timeout.connect(queue_free)
