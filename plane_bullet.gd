extends Area2D

var speed := 1200.0
const DAMAGE := 10.0 # You can adjust how much damage each bullet does here

func _physics_process(delta: float) -> void:
	# Move forward continuously in the direction the bullet is rotated
	position += transform.x * speed * delta


func _on_body_entered(body: Node2D) -> void:
	# 1. Safety check: Don't let the player shoot themselves
	if body.is_in_group("player_plane"):
		return
		
	# 2. Check if the bullet hit an enemy
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		
	# 3. Destroy the bullet after hitting the enemy (or a wall)
	queue_free()
