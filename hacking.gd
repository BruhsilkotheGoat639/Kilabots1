extends Control

@onready var preview_box: TextEdit = $Text
@onready var display: RichTextLabel = $RichTextLabel
@onready var input_box: TextEdit = $Input
@onready var hacked_sound: AudioStreamPlayer2D = $HackedSound
@onready var hackedoverride_sound: AudioStreamPlayer2D = $Hackedoverride

var target_word: String = ""
var possible_tasks := [
	"init_warp_sequence", 
	"sudo open_portal --force", 
	"Gate.unlock({ protocol: \"TESSERACT\", force: true });",
	"firewall.bypass = true",
	"Anticonstitutionnellement",
	"movement_velocity = 800.0",
	"if key override: movement.unlocked()"
]

func _ready() -> void:
	display.scroll_following = true
	preview_box.editable = false 
	input_box.gui_input.connect(_on_text_edit_gui_input)
	display.focus_mode = Control.FOCUS_NONE
	
	await get_tree().create_timer(10.0).timeout
	start_new_task()


func start_new_task() -> void:
	hacked_sound.play()
	target_word = possible_tasks.pick_random()
	preview_box.text = target_word 
	display.text += "\n\n[SYSTEM] INTRUSION DETECTED. Type the previewed text to authenticate."
	
	# Mark the plane as hacked to slow it down
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.has_method("set_hacked"):
			p.set_hacked(true)
			
	input_box.grab_focus()


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			get_viewport().set_input_as_handled()
			return
			
		if event.pressed and event.keycode == KEY_ENTER and not event.shift_pressed:
			get_viewport().set_input_as_handled()
			submit_command(input_box.text)


func submit_command(new_text: String) -> void:
	var clean_text = new_text.strip_edges()
	
	if clean_text == "":
		input_box.text = ""
		return
		
	display.text += "\n> " + clean_text
	
	if clean_text == target_word:
		task_completed()
	else:
		display.text += "\n[ERROR] Authentication failed. Try again."
	
	input_box.text = ""


func task_completed() -> void:
	hackedoverride_sound.play()
	display.text += "\n[SUCCESS] Access granted! Override suspended. (+10 HP)"
	preview_box.text = "" 
	
	# Un-hack the plane, return to full speed, and heal 10 HP
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			if p.has_method("set_hacked"):
				p.set_hacked(false)
			if p.has_method("heal"):
				p.heal(10.0)
	
	input_box.release_focus()
	
	var random_delay = randf_range(1.0, 10.0)
	await get_tree().create_timer(random_delay).timeout
	
	start_new_task()
