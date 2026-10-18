extends CharacterBody2D

var health = 30

func take_damage(amount: int) -> void:
	health -= amount
	print("Enemy health is now: ", health)
	
	if health <= 0:
		queue_free() # Destroy the enemy
