extends Node

func _ready() -> void:
	# Keep animating numbers even if the Boss triggers Time Stop
	process_mode = Node.PROCESS_MODE_ALWAYS

func spawn_damage(world_pos: Vector2, amount: int, is_player_hit: bool = false) -> void:
	var current_scene = get_tree().current_scene
	if not current_scene:
		return

	# Use a Node2D wrapper so scaling and positioning stay centered at the hit location
	var holder = Node2D.new()
	holder.process_mode = Node.PROCESS_MODE_ALWAYS
	holder.z_index = 50 # Render in front of sprites
	
	# Add a slight random offset so rapid hits don't stack on the exact same pixel
	var random_x = randf_range(-15.0, 15.0)
	holder.global_position = world_pos + Vector2(random_x, -25.0)

	var label = Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(-40, -15)
	label.custom_minimum_size = Vector2(80, 30)

	# Style the text with a black outline and color-coding
	var settings = LabelSettings.new()
	settings.font_size = 20
	settings.outline_size = 5
	settings.outline_color = Color.BLACK
	# Red when players take damage, Gold/Yellow when enemies or the Boss take damage
	settings.font_color = Color(1.0, 0.25, 0.25) if is_player_hit else Color(1.0, 0.9, 0.2)
	label.label_settings = settings

	holder.add_child(label)
	current_scene.add_child(holder)

	# Pop-up and fade-out animation
	holder.scale = Vector2(0.5, 0.5)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	
	# Pop scale up, float upward, and fade out
	tween.tween_property(holder, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "global_position:y", holder.global_position.y - 35.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 0.0, 0.3).set_delay(0.35)

	await tween.finished
	if is_instance_valid(holder):
		holder.queue_free()
