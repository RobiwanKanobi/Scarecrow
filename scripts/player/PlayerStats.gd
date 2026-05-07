extends Node

signal health_changed(new_health: float, max_health: float)
signal hunger_changed(new_hunger: float, max_hunger: float)

@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
@export var hunger_drain_per_minute: float = 3.0
@export var night_exposure_damage_per_sec: float = 2.0
@export var night_exposure_grace_sec: float = 3.0

var health: float = 100.0
var hunger: float = 100.0

var _is_night: bool = false
var _exposure_timer: float = 0.0
var _player: Node  # PlayerController (CharacterBody3D)
var _dead: bool = false

func _ready() -> void:
	_player = get_parent()
	GameEvents.night_started.connect(_on_night_started)
	GameEvents.day_started.connect(_on_day_started)

func _process(delta: float) -> void:
	if _dead:
		return

	hunger -= (hunger_drain_per_minute / 60.0) * delta
	hunger = clampf(hunger, 0.0, max_hunger)
	hunger_changed.emit(hunger, max_hunger)

	if hunger <= 0.0:
		take_damage(1.5 * delta)

	if _is_night:
		var in_light: bool = _player.get("is_in_light")
		if not in_light:
			_exposure_timer += delta
			if _exposure_timer >= night_exposure_grace_sec:
				take_damage(night_exposure_damage_per_sec * delta)
		else:
			_exposure_timer = 0.0

func take_damage(amount: float) -> void:
	if _dead:
		return
	health -= amount
	health = clampf(health, 0.0, max_health)
	health_changed.emit(health, max_health)
	GameEvents.player_damaged.emit(amount)

	if health <= 0.0:
		_dead = true
		GameEvents.player_died.emit()

func heal(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)
	GameEvents.player_healed.emit(amount)

func restore_hunger(amount: float) -> void:
	hunger = minf(hunger + amount, max_hunger)
	hunger_changed.emit(hunger, max_hunger)

func _on_night_started(_day_count: int) -> void:
	_is_night = true

func _on_day_started(_day_count: int) -> void:
	_is_night = false
	_exposure_timer = 0.0
