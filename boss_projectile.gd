extends Area2D

const SPEED = 250.0
const DAMAGE = 50
var direction := Vector2.RIGHT 

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta

func _on_body_entered(body: Node2D) -> void:
	# Ignore other enemies
	if body.is_in_group("enemy"):
		return
		
	# Hurt the player
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DAMAGE)
		
	# Disappear when hitting the player or a wall
	queue_free()
