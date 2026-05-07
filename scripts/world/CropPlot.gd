extends StaticBody3D

enum CropState { PLANTED, GROWING, READY, DEAD }

@export var grow_time_planted: float = 25.0
@export var grow_time_growing: float = 25.0
@export var max_health: float = 30.0

var current_health: float = 30.0
var crop_state: CropState = CropState.PLANTED
var _grow_timer: float = 0.0
var _visual: MeshInstance3D

const STATE_COLORS: Dictionary = {
	CropState.PLANTED: Color(0.55, 0.40, 0.20),
	CropState.GROWING: Color(0.30, 0.60, 0.20),
	CropState.READY: Color(0.15, 0.82, 0.15),
	CropState.DEAD: Color(0.30, 0.20, 0.12),
}

func _ready() -> void:
	current_health = max_health
	_visual = get_node_or_null("Visual")
	var sprite := get_node_or_null("Sprite3D")
	if sprite:
		_visual = null  # Use sprite path instead
	add_to_group("crop_plots")
	add_to_group("placeables")
	_update_visual()

func _process(delta: float) -> void:
	match crop_state:
		CropState.PLANTED:
			_grow_timer += delta
			if _grow_timer >= grow_time_planted:
				_grow_timer = 0.0
				crop_state = CropState.GROWING
				_update_visual()
		CropState.GROWING:
			_grow_timer += delta
			if _grow_timer >= grow_time_growing:
				_grow_timer = 0.0
				crop_state = CropState.READY
				_update_visual()
				GameEvents.message_requested.emit("A crop is ready to harvest! (press E)")

func interact(_player: Node) -> void:
	match crop_state:
		CropState.READY:
			_harvest()
		CropState.DEAD:
			GameEvents.message_requested.emit("This crop was destroyed.")
		_:
			GameEvents.message_requested.emit("Crop is still growing...")

func _harvest() -> void:
	var inventory := get_tree().get_first_node_in_group("inventory_manager")
	if inventory:
		inventory.add_item("berry", 2)
		inventory.add_item("seed", 1)
	crop_state = CropState.PLANTED
	current_health = max_health
	_grow_timer = 0.0
	_update_visual()
	GameEvents.message_requested.emit("Harvested: 2 berry, 1 seed")

func take_damage(amount: float) -> void:
	if crop_state == CropState.DEAD:
		return
	current_health -= amount
	if current_health <= 0.0:
		crop_state = CropState.DEAD
		_update_visual()
		GameEvents.crop_destroyed.emit()
		GameEvents.message_requested.emit("A crop was destroyed by crows!")

func _update_visual() -> void:
	var sprite := get_node_or_null("Sprite3D") as Sprite3D
	if sprite:
		match crop_state:
			CropState.PLANTED: sprite.modulate = Color(0.7, 0.5, 0.3)
			CropState.GROWING: sprite.modulate = Color(0.6, 0.9, 0.5)
			CropState.READY:   sprite.modulate = Color(1.0, 1.0, 1.0)
			CropState.DEAD:    sprite.modulate = Color(0.3, 0.2, 0.1, 0.6)
		return
	if _visual == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = STATE_COLORS.get(crop_state, Color.WHITE)
	_visual.material_override = mat
