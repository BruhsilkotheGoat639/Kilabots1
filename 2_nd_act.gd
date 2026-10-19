extends Node2D

@export var enemy_plane_scene: PackedScene

@onready var timer_label = $CanvasLayer/TimerLabel # Adjust path to your Label
@onready var player = $Plane # Adjust path to your player node
@onready var hp_label = $CanvasLayer/Healthbar/HPLabel
@onready var fade = $Fading

var time_left: float = 180.0 # 3 minutes in seconds
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5 # Spawns a new enemy every 3 seconds

func _ready() -> void:
	fade.play("Fade out")

func _process(delta: float) -> void:
	# 1. Handle Countdown
	if time_left > 0:
		time_left -= delta
		update_timer_ui()
		
		if time_left <= 0:
			trigger_victory()
			
	# 2. Handle Enemy Spawning
	if is_instance_valid(player):
		# --- NEW: Continuously update the label with the player's exact health ---
		hp_label.text = "HP: " + str(player.health)
		
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_enemy()
			spawn_timer = spawn_interval
	else:
		# --- NEW: If the player gets destroyed, lock the label at 0 ---
		hp_label.text = "HP: 0"

func update_timer_ui() -> void:
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	# Formats the time to look like "03:00"
	timer_label.text = "%02d:%02d" % [minutes, seconds] 

func spawn_enemy() -> void:
	if not enemy_plane_scene:
		return
		
	# Gather every Marker2D you added to the "enemy_spawns" group
	var spawn_points = get_tree().get_nodes_in_group("enemy_spawns")
	
	if spawn_points.is_empty():
		print("No spawn points found! Make sure they are in the 'enemy_spawns' group.")
		return
		
	var enemy = enemy_plane_scene.instantiate()
	
	# Pick one random Marker2D from the list
	var chosen_spawn = spawn_points.pick_random()
	
	# Move the newly created enemy to that marker's exact location
	enemy.global_position = chosen_spawn.global_position
	
	add_child(enemy)

func trigger_victory() -> void:
	timer_label.text = "00:00 - SURVIVED!"
	# Add victory transition code here (e.g., loading the next level)
