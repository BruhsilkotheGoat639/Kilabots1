extends Control

@onready var main_buttons = $HBoxContainer

func _ready() -> void:
	ScoreManager.reset_score()
	main_buttons.show()
	# Connect to the global Autoload's custom signal
	SettingsPanel.settings_closed.connect(_on_settings_closed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().paused = false 
	get_tree().quit() 

func _on_settings_pressed() -> void:
	main_buttons.hide()
	# Call the global Autoload by its project name
	SettingsPanel.show() 

func _on_settings_closed() -> void:
	main_buttons.show()
