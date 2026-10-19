extends CanvasLayer

@onready var vbox_container = $ColorRect/VBoxContainer
@onready var resume_button = $ColorRect/VBoxContainer/ResumeButton
@onready var settings_button = $ColorRect/VBoxContainer/Settings
@onready var quit_button = $ColorRect/VBoxContainer/Quit

func _ready() -> void:
	hide()
	
	if not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _process(_delta: float) -> void:
	if SettingsPanel.visible or GameOver.visible:
			return
	if Input.is_action_just_pressed("Pause"):
		# Do not allow the pause menu to trigger in the Main Menu scene
		var current_scene = get_tree().current_scene
		if current_scene and (current_scene.name == "Menu" or current_scene.scene_file_path.ends_with("menu.tscn")):
			return
			
		# Optional: also ignore the pause key while the SettingsPanel is open
		if SettingsPanel.visible:
			return
			
		toggle_pause()

func toggle_pause() -> void:
	var new_pause_state = not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state
	
	if visible:
		vbox_container.show()

func _on_resume_pressed() -> void:
	toggle_pause()

func _on_settings_pressed() -> void:
	vbox_container.hide()
	SettingsPanel.show()
	await SettingsPanel.settings_closed
	vbox_container.show()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	hide()
	get_tree().quit()
