extends Node

var _game_over: bool = false
var _victory: bool = false

func _ready() -> void:
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.day_started.connect(_on_day_started)

func _on_player_died() -> void:
	if _game_over or _victory:
		return
	_game_over = true
	GameEvents.message_requested.emit("GAME OVER — You have fallen apart...")

func _on_day_started(day_count: int) -> void:
	if _game_over or _victory:
		return
	if day_count >= 4:
		_victory = true
		GameEvents.message_requested.emit("VICTORY! You survived 3 nights! The farm endures!")
