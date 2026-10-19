extends ProgressBar

var plane: Node2D = null

func _ready() -> void:
	# Find the plane node in the scene
	plane = get_tree().get_first_node_in_group("player")
	if not plane:
		var root = get_tree().current_scene
		if root.has_node("Plane"):
			plane = root.get_node("Plane")
			
	if plane and "MAX_HEALTH" in plane:
		max_value = plane.MAX_HEALTH
	else:
		max_value = 100.0

func _process(_delta: float) -> void:
	if is_instance_valid(plane) and "health" in plane:
		value = plane.health
	else:
		# Continuously look for the plane if it hasn't spawned yet
		plane = get_tree().get_first_node_in_group("player")
