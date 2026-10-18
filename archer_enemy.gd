extends CharacterBody2D

const GRAVITY = 1000.0
const FIRE_COOLDOWN = 1.5
const MAX_HEALTH = 50

# --- Stagger Balance Settings ---
const STAGGER_DURATION = 0.4
const STAGGER_COOLDOWN = 2.5

var health = MAX_HEALTH
var can_shoot = true
var is_attacking = false 
var is_staggered = false
var can_be_staggered = true
var attack_token: int = 0

var current_target: Node2D = null

@export var enemy_arrow_scene: PackedScene

@onready var anim = $Animation 
@onready var muzzle = $Muzzle
@onready var detection_area = $DetectionArea

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		
	move_and_slide()
	
	# Stop aiming or shooting while staggered
	if is_staggered:
		return

	if current_target:
		# 1. Flip the archer visually based on whether the player is left or right
		var distance_x = current_target.global_position.x - global_position.x
		if distance_x != 0:
			anim.flip_h = (distance_x < 0)
			muzzle.position.x = abs(muzzle.position.x) * sign(distance_x)
		
		# 2. Shoot omnidirectionally (only if not already in the middle of an attack animation)
		if can_shoot and not is_attacking:
			# Calculate the exact 2D directional vector towards the player
			var aim_direction = (current_target.global_position - muzzle.global_position).normalized()
			fire_arrow(aim_direction)
			
	# --- NEW: Global Animation Handling ---
	if not is_attacking:
		anim.play("Idle")


func fire_arrow(aim_dir: Vector2) -> void:
	can_shoot = false
	is_attacking = true
	attack_token += 1
	var my_token = attack_token
	
	# Play the attack animation and wait for it to finish before firing
	anim.play("Attack")
	await anim.animation_finished
	
	# Abort firing if the archer was staggered during the bow draw animation
	if my_token != attack_token or is_staggered:
		return
	
	if enemy_arrow_scene:
		var arrow = enemy_arrow_scene.instantiate()
		get_tree().current_scene.add_child(arrow)
		arrow.global_position = muzzle.global_position
		
		# Apply the omnidirectional vector
		arrow.direction = aim_dir
		
		# Rotate the arrow graphic so the pointy end faces the player
		arrow.rotation = aim_dir.angle()
		
	is_attacking = false
			
	await get_tree().create_timer(FIRE_COOLDOWN).timeout
	if my_token == attack_token:
		can_shoot = true


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and current_target == null:
		current_target = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == current_target:
		current_target = null
		
		var overlapping = detection_area.get_overlapping_bodies()
		for b in overlapping:
			if b.is_in_group("player"):
				current_target = b
				break


func take_damage(amount: int) -> void:
	health -= amount
	print("Archer took ", amount, " damage! Health: ", health)
	
	flash_red()
	
	if health <= 0:
		queue_free()
		return
		
	if can_be_staggered:
		apply_stagger()


func flash_red() -> void:
	anim.modulate = Color(1.0, 0.25, 0.25)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)


func apply_stagger() -> void:
	is_staggered = true
	can_be_staggered = false
	
	# Cancel any in-progress attack
	attack_token += 1
	is_attacking = false
	anim.play("Idle")
	
	await get_tree().create_timer(STAGGER_DURATION).timeout
	is_staggered = false
	
	# Wait a tiny bit before allowing them to shoot again after recovering
	await get_tree().create_timer(0.3).timeout
	if not is_attacking:
		can_shoot = true
		
	await get_tree().create_timer(STAGGER_COOLDOWN).timeout
	can_be_staggered = true
