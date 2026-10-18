extends Area2D

@export var enemy_scene: PackedScene
@export var total_enemies_to_spawn: int = 20
@export var spawn_interval: float = 0.8

@onready var spawner: Marker2D = $HordeSpawner if has_node("HordeSpawner") else $"../HordeSpawner"
@onready var enemies_container: Node = get_node_or_null("../Enemies")

var players_in_zone: int = 0
var has_triggered: bool = false

func _ready() -> void:
	# Automatically load melee_enemyHorde.tscn if not assigned in the Inspector
	if not enemy_scene:
		if ResourceLoader.exists("res://melee_enemyHorde.tscn"):
			enemy_scene = load("res://melee_enemyHorde.tscn")
		elif ResourceLoader.exists("res://Enemies/melee_enemyHorde.tscn"):
			enemy_scene = load("res://Enemies/melee_enemyHorde.tscn")
			
	# Connect the Area2D signals through code
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	# If one player is waiting in the zone when the other player dies outside, trigger immediately
	if players_in_zone > 0 and not has_triggered:
		check_horde_trigger()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_zone += 1
		check_horde_trigger()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		players_in_zone -= 1

func check_horde_trigger() -> void:
	# Count how many players are still alive in the level
	var alive_players = get_tree().get_nodes_in_group("player").size()
	
	# Trigger if all surviving players are inside the zone (and at least 1 is alive)
	if alive_players > 0 and players_in_zone >= alive_players and not has_triggered:
		has_triggered = true
		start_horde()

func start_horde() -> void:
	print("Horde event started!")
	
	for i in range(total_enemies_to_spawn):
		spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout

func spawn_enemy() -> void:
	if not enemy_scene:
		print("Could not find melee_enemyHorde.tscn! Assign it in the Inspector.")
		return
		
	var enemy = enemy_scene.instantiate()
	
	# Spawn at the HordeSpawner Marker2D position
	enemy.global_position = spawner.global_position
	
	# --- FIX: Use call_deferred so Godot waits for physics calculations to finish ---
	if enemies_container:
		enemies_container.call_deferred("add_child", enemy)
	else:
		get_parent().call_deferred("add_child", enemy)
