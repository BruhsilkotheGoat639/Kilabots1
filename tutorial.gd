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
	print_all_players()
	
func print_all_players() -> void:
	var players = get_tree().get_nodes_in_group("player")
	print("--- TOTAL PLAYERS FOUND: ", players.size(), " ---")
	for p in players:
		print("Node Name: ", p.name, " | Path: ", p.get_path(), " | Visible: ", p.visible)
	
func _process(delta: float) -> void:
	if is_game_over:
		return
