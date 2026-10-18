extends Camera2D

@export var move_speed: float = 5.0
@export var zoom_speed: float = 3.0
@export var min_zoom: float = 0.5 # The furthest the camera can zoom out
@export var max_zoom: float = 2.0 # The closest the camera can zoom in
@export var margin: Vector2 = Vector2(200, 200) # Pixel buffer around the screen edges

var targets: Array[Node2D] = []

func _process(delta: float) -> void:
	# 0. CLEANUP: Loop backwards through the array and remove dead targets
	for i in range(targets.size() - 1, -1, -1):
		# is_instance_valid checks if the node still exists in the game
		if not is_instance_valid(targets[i]) or targets[i].is_queued_for_deletion():
			targets.remove_at(i)

	if targets.is_empty():
		return

	# 1. Position: Find the exact midpoint of all targets
	var center_pos := Vector2.ZERO
	for target in targets:
		center_pos += target.position
	center_pos /= targets.size()
	
	# Smoothly pan to the center
	position = position.lerp(center_pos, move_speed * delta)
	
	
	# 2. Zoom: Find the bounding box that fits all targets
	var rect := Rect2(targets[0].position, Vector2.ZERO)
	for target in targets:
		rect = rect.expand(target.position)
		
	# Pad the bounding box with our margin so players aren't cut off
	rect = rect.grow_individual(margin.x, margin.y, margin.x, margin.y)
	
	# 3. Apply Zoom: Compare screen size to the bounding box size
	var screen_size := get_viewport_rect().size
	var z: float = min(screen_size.x / rect.size.x, screen_size.y / rect.size.y)
	
	# Clamp the zoom so it doesn't get too close or too far
	z = clamp(z, min_zoom, max_zoom)
	
	# Smoothly adjust the zoom
	zoom = zoom.lerp(Vector2.ONE * z, zoom_speed * delta)

# Helper function to assign players to the camera
func add_target(target: Node2D) -> void:
	if not target in targets:
		targets.append(target)
