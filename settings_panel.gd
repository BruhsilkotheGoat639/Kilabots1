extends CanvasLayer

signal settings_closed 

@onready var fullscreen_toggle: CheckButton = $FullScreen/FullScreenToggle
@onready var sfx_slider: HSlider = $SFXSlider/SFXSliderButton
@onready var sfx_label: Label = $SFXSlider/SFXVolumeLabel

var sfx_bus_index: int = -1

func _ready() -> void:
	hide()
	
	# 1. Sync Fullscreen Toggle state
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		fullscreen_toggle.button_pressed = true
	else:
		fullscreen_toggle.button_pressed = false
		
	# 2. Find the "Sound Effect" Audio Bus and sync the slider & label
	sfx_bus_index = AudioServer.get_bus_index("Sound Effect")
	if sfx_bus_index == -1:
		push_warning("Audio Bus 'Sound Effect' not found!")
	else:
		var current_db = AudioServer.get_bus_volume_db(sfx_bus_index)
		var val = db_to_linear(current_db)
		sfx_slider.value = val
		update_sfx_label(val)
		
	if not sfx_slider.value_changed.is_connected(_on_sfx_slider_value_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)


func update_sfx_label(value: float) -> void:
	if sfx_label:
		sfx_label.text = str(int(value * 100)) + "%"


func _on_sfx_slider_value_changed(value: float) -> void:
	update_sfx_label(value)
	
	if sfx_bus_index == -1:
		return
		
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_index, value <= 0.01)


func _on_back_pressed() -> void:
	hide()
	settings_closed.emit() 


func _on_full_screen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
