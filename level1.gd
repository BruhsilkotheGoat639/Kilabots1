extends Node2D

@onready var camera = $DynamicCamera
@onready var player1 = $Players/P1
@onready var player2 = $Players/P2
@onready var fade = $DynamicCamera/Fades

var is_game_over: bool = false


func _ready() -> void:
	# Register both players to the camera on startup
	camera.add_target(player1)
	camera.add_target(player2)
	fade.play("Fade Out")
	
func _process(delta: float) -> void:
	if is_game_over:
		return

	var alive_players = get_tree().get_nodes_in_group("player")
	
	if alive_players.is_empty():
		trigger_restart()
		

func trigger_restart() -> void:
	is_game_over = true
	print("All players are dead! Level Restarting")
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
