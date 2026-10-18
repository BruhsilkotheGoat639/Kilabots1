extends Area2D

const SPEED = 600.0
const DAMAGE = 5
var direction := Vector2.RIGHT

func _physics_process(delta: float) -> void:
	# Move the arrow horizontally every frame
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	# Ignore the players so they don't shoot themselves
	if body.is_in_group("player"):
		return
		
	# Deal damage if it hits an enemy
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		
	# Destroy the arrow when it hits an enemy or a wall
	queue_free()
