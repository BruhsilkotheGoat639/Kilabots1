extends Area2D

# The path to your next level
@export var next_scene_path: String = "res://1_st_level.tscn"
@onready var fade = $"../DynamicCamera/Fades"

var players_in_zone: int = 0
var is_transitioning: bool = false

func _ready() -> void:
	# Connect the Area2D signals through code
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_zone += 1
		check_scene_change()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_zone -= 1

func check_scene_change() -> void:
	# Count how many players are still alive in the level
	var alive_players = get_tree().get_nodes_in_group("player").size()
	
	# Trigger if all surviving players are inside the zone (and at least 1 is alive)
	if alive_players > 0 and players_in_zone >= alive_players and not is_transitioning:
		is_transitioning = true
		print("All surviving players entered! Changing scene...")
		fade.play("Fade in")
		await get_tree().create_timer(2.5).timeout
		get_tree().change_scene_to_file(next_scene_path)
