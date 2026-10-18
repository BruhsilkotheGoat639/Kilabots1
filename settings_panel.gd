extends CanvasLayer

signal settings_closed 

# Matches the exact scene tree shown in your screenshot
@onready var fullscreen_toggle = $FullScreen/FullScreenToggle

func _ready() -> void:
	hide() 
	
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		fullscreen_toggle.button_pressed = true
	else:
		fullscreen_toggle.button_pressed = false

# Make sure your "Back" button's pressed signal is connected to this!
func _on_back_pressed() -> void:
	hide()
	settings_closed.emit() 

# Make sure your "FullScreenToggle" toggled signal is connected to this!
func _on_full_screen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
