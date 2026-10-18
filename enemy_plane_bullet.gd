extends Area2D

const SPEED = 600.0
const DAMAGE = 0.5
var direction := Vector2.RIGHT 

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_plane") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		
	# Ignore other enemies
	if body.is_in_group("enemy"):
		return
		
	queue_free()
