extends StaticBody3D

@export var light_radius: float = 8.0
@export var fuel_duration: float = 70.0

var _omni_light: OmniLight3D
var _protection_area: Area3D
var _fuel_timer: float = 0.0
var _is_night: bool = false
var _active: bool = true

func _ready() -> void:
	add_to_group("placeables")
	add_to_group("light_sources")

	_omni_light = get_node_or_null("OmniLight3D")
	_protection_area = get_node_or_null("ProtectionArea")

	if _omni_light:
		_omni_light.omni_range = light_radius

	if _protection_area:
		var col := _protection_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col:
			var sphere := SphereShape3D.new()
			sphere.radius = light_radius
			col.shape = sphere
		_protection_area.body_entered.connect(_on_body_entered)
		_protection_area.body_exited.connect(_on_body_exited)

	GameEvents.night_started.connect(_on_night_started)
	GameEvents.day_started.connect(_on_day_started)

func _process(delta: float) -> void:
	if not _active or not _is_night:
		return
	_fuel_timer += delta
	if _fuel_timer >= fuel_duration:
		_extinguish()

func _extinguish() -> void:
	_active = false
	if _omni_light:
		_omni_light.visible = false
	# Eject any players from light tracking
	if _protection_area:
		for body: Node3D in _protection_area.get_overlapping_bodies():
			if body.is_in_group("player"):
				body.light_sources_touching = maxi(0, body.light_sources_touching - 1)
	GameEvents.message_requested.emit("A light source has burned out!")

func _on_night_started(_day_count: int) -> void:
	_is_night = true
	_fuel_timer = 0.0

func _on_day_started(_day_count: int) -> void:
	_is_night = false
	_fuel_timer = 0.0
	if not _active:
		_active = true
		if _omni_light:
			_omni_light.visible = true

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.light_sources_touching += 1

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.light_sources_touching = maxi(0, body.light_sources_touching - 1)
