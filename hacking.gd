extends Control

# Match the exact names from your scene tree
@onready var preview_box: TextEdit = $Text # The top preview box
@onready var display: RichTextLabel = $RichTextLabel # The middle log
@onready var input_box: TextEdit = $Input # The bottom typing box

var target_word: String = ""
var possible_tasks := [
	"init_warp_sequence", 
	"sudo open_portal --force", 
	"Gate.unlock({ protocol: \"TESSERACT\", force: true });",
	#"inject_payload [0x7FA9B] -> trigger_dimensional_rift()",
	#'ssh root@bridge_nexus -p 8080 "execute_rift"',
	"firewall.bypass = true",
	"Anticonstitutionnellement",
	"movement_velocity = 800.0",
	"if key override: movement.unlocked()"
]

func _ready() -> void:
	display.scroll_following = true
	
	# Prevent the player from clicking and typing in the preview box
	preview_box.editable = false 
	
	input_box.gui_input.connect(_on_text_edit_gui_input)
	display.focus_mode = Control.FOCUS_NONE
	
	await get_tree().create_timer(10.0).timeout
	start_new_task()


func start_new_task() -> void:
	target_word = possible_tasks.pick_random()
	
	# Display the target word in the top TextEdit preview box
	preview_box.text = target_word 
	
	display.text += "\n\n[SYSTEM] INTRUSION DETECTED. Type the previewed text to authenticate."
	
	# Automatically grab focus to instantly freeze the plane and allow typing
	input_box.grab_focus()


func _on_text_edit_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# Ignore Arrow Keys so the text cursor doesn't move while flying
		if event.keycode in [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			get_viewport().set_input_as_handled()
			return
			
		# Handle Enter key submission
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
	
	# Clear the bottom text box for the next attempt
	input_box.text = ""


func task_completed() -> void:
	display.text += "\n[SUCCESS] Access granted! Override suspended."
	
	# Clear the preview box while waiting for the next task
	preview_box.text = "" 
	
	# IMPORTANT: Release focus so the plane can move again!
	input_box.release_focus()
	
	print("Minigame completed!")
	
	# Pick a random delay between 1 and 13 seconds
	var random_delay = randf_range(1.0, 10.0)
	await get_tree().create_timer(random_delay).timeout
	
	start_new_task()
