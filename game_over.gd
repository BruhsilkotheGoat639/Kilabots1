extends CanvasLayer

@onready var retry_button = $Retry
@onready var menu_button = $Home

var is_game_over: bool = false
var level_had_players: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _process(_delta: float) -> void:
	# Do not check for Game Over while on the Main Menu
	var current_scene = get_tree().current_scene
	if not current_scene or current_scene.name == "Menu" or current_scene.scene_file_path.ends_with("menu.tscn"):
		level_had_players = false
		return

	if is_game_over:
		return

	# Check how many players are currently alive in the "player" group
	var alive_count := 0
	var players = get_tree().get_nodes_in_group("player")
	
	for p in players:
		if is_instance_valid(p):
			# Check if the player has a health variable and is still above 0 HP
			if "health" in p:
				if p.health > 0:
					alive_count += 1
			else:
				alive_count += 1

	# Once at least 1 player has spawned into the level, start monitoring for a total wipeout
	if alive_count > 0:
		level_had_players = true
	elif level_had_players and alive_count == 0:
		trigger_game_over()

func trigger_game_over() -> void:
	if is_game_over:
		return
		
	is_game_over = true
	level_had_players = false
	
	# Slight delay so players can see the final hit/death animation before freezing
	await get_tree().create_timer(0.8, true, false, true).timeout
	
	get_tree().paused = true
	show()

func _on_retry_pressed() -> void:
	is_game_over = false
	level_had_players = false
	hide()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	is_game_over = false
	level_had_players = false
	hide()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
