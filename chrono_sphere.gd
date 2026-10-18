extends Area2D

const SLOW_FACTOR := 0.15 # 15% normal speed
const DURATION := 5.0
const PLAYER_GRAVITY := 1000.0

var tracked_positions: Dictionary = {}

func _ready() -> void:
	# Pop the bubble after DURATION seconds
	await get_tree().create_timer(DURATION).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	await tween.finished
	queue_free()

func _physics_process(delta: float) -> void:
	var current_nodes: Array = []
	
	# Collect both physics bodies (P1/P2) and areas (Arrows/Bullets)
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			current_nodes.append(body)
			# Counteract 85% of gravity so jumps also happen in slow-motion
			if body is CharacterBody2D and not body.is_on_floor():
				body.velocity.y -= PLAYER_GRAVITY * delta * (1.0 - SLOW_FACTOR)
				
	for area in get_overlapping_areas():
		if area != self and not area.is_in_group("boss"):
			current_nodes.append(area)
			
	# Pull each trapped object back toward its previous frame position to slow it down
	var next_positions: Dictionary = {}
	for node in current_nodes:
		if is_instance_valid(node):
			if tracked_positions.has(node):
				node.global_position = tracked_positions[node].lerp(node.global_position, SLOW_FACTOR)
			next_positions[node] = node.global_position
			
	tracked_positions = next_positions
