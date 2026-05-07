extends Node

@export var day_duration: float = 120.0
@export var night_duration: float = 60.0

var day_count: int = 1
var is_night: bool = false

var _elapsed: float = 0.0
var _phase_duration: float = 0.0
var _directional_light: DirectionalLight3D
var _environment: WorldEnvironment

func _ready() -> void:
	add_to_group("time_manager")
	_phase_duration = day_duration
	call_deferred("_find_lighting")
	call_deferred("_emit_initial")

func _find_lighting() -> void:
	_directional_light = get_parent().get_node_or_null("DirectionalLight3D")
	_environment = get_parent().get_node_or_null("WorldEnvironment")

func _emit_initial() -> void:
	GameEvents.day_started.emit(day_count)
	_apply_day_lighting()

func _process(delta: float) -> void:
	_elapsed += delta
	var normalized: float = clampf(_elapsed / _phase_duration, 0.0, 1.0)
	GameEvents.time_changed.emit(normalized)

	if _elapsed >= _phase_duration:
		_elapsed = 0.0
		_transition()

func _transition() -> void:
	is_night = not is_night
	if is_night:
		_phase_duration = night_duration
		GameEvents.night_started.emit(day_count)
		GameEvents.message_requested.emit("Night %d has begun! Crows are coming!" % day_count)
		_apply_night_lighting()
	else:
		day_count += 1
		_phase_duration = day_duration
		GameEvents.day_started.emit(day_count)
		if day_count <= 3:
			GameEvents.message_requested.emit("Day %d has begun. Gather and prepare!" % day_count)

func _apply_day_lighting() -> void:
	if _directional_light:
		_directional_light.light_energy = 1.5
		_directional_light.light_color = Color(1.0, 0.95, 0.8)
	if _environment and _environment.environment:
		var env := _environment.environment
		env.ambient_light_color = Color(0.7, 0.7, 0.8)
		env.ambient_light_energy = 1.0
		env.background_color = Color(0.53, 0.64, 0.82)

func _apply_night_lighting() -> void:
	if _directional_light:
		_directional_light.light_energy = 0.15
		_directional_light.light_color = Color(0.3, 0.3, 0.6)
	if _environment and _environment.environment:
		var env := _environment.environment
		env.ambient_light_color = Color(0.05, 0.05, 0.15)
		env.ambient_light_energy = 0.2
		env.background_color = Color(0.05, 0.05, 0.2)

func get_normalized_time() -> float:
	return clampf(_elapsed / _phase_duration, 0.0, 1.0)
