extends CanvasLayer

var tracked_entity: Node = null
var entity_name: String = ""

var container: Control
var progress_bar: TextureProgressBar # Or use a standard ProgressBar if you prefer
var name_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 90 # Renders above game elements, below pause/game over menus
	
	# Build the UI programmatically so you don't need a separate .tscn file
	container = Control.new()
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.custom_minimum_size = Vector2(0, 80)
	container.position = Vector2(0, 20)
	add_child(container)

	# Background / Bar styling container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER_TOP)
	vbox.position = Vector2(-150, 15)
	vbox.custom_minimum_size = Vector2(300, 40)
	container.add_child(vbox)

	name_label = Label.new()
	name_label.text = "TARGET"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var label_settings = LabelSettings.new()
	label_settings.font_size = 16
	label_settings.outline_size = 4
	label_settings.outline_color = Color.BLACK
	label_settings.font_color = Color.WHITE
	name_label.label_settings = label_settings
	vbox.add_child(name_label)

	progress_bar = TextureProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(300, 20)
	# You can assign a custom fill/under texture here if you have them, 
	# or fallback to a standard ProgressBar below if you prefer a solid theme!
	vbox.add_child(progress_bar)
	
	# Start hidden until an entity registers
	container.hide()

func _process(_delta: float) -> void:
	if not is_instance_valid(tracked_entity):
		if container.visible:
			container.hide()
		return

	if not container.visible:
		container.show()

	# Dynamically read health properties from whatever entity is registered
	var hp = tracked_entity.get("health") if "health" in tracked_entity else 0
	var max_hp = tracked_entity.get("max_health") if "max_health" in tracked_entity else (tracked_entity.get("MAX_HEALTH") if "MAX_HEALTH" in tracked_entity else 100.0)

	if hp <= 0:
		container.hide()
		tracked_entity = null
		return

	# Update bar percentage smoothly
	progress_bar.max_value = max_hp
	progress_bar.value = hp

func track_entity(entity: Node, display_name: String = "") -> void:
	tracked_entity = entity
	if display_name != "":
		name_label.text = display_name
	else:
		name_label.text = entity.name.to_upper()
	container.show()
