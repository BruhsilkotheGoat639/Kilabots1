extends CharacterBody2D

const SPEED = 115.0
const DAMAGE = 10
const JUMP_VELOCITY = -500.0
const PLATFORM_LAYER = 2 

# --- Stagger Balance Settings ---
const STAGGER_DURATION = 0.4
const STAGGER_COOLDOWN = 2.5

# Change this value directly in the Godot Inspector
@export var detection_range: float = 200.0

@onready var ledge_check: RayCast2D = $LedgeCheck
@onready var sprite: AnimatedSprite2D = $MummyAnimation 
@onready var hit_sound_melee: AudioStreamPlayer2D = $HitSoundMelee
@onready var hit_sound_arrow: AudioStreamPlayer2D = $HitSoundArrow

var gravity = 1000.0
var health = 100.0	

# State trackers
var is_preparing_jump = false
var is_dropping = false
var is_attacking = false 
var is_staggered = false
var can_be_staggered = true
var attack_token: int = 0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		
	# 1. Halt all normal movement and actions if staggered
	if is_staggered:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return
		
	var target = get_closest_player()
	
	if target:
		if is_attacking or is_preparing_jump:
			velocity.x = 0
		else:
			var direction = sign(target.global_position.x - global_position.x)
			velocity.x = direction * SPEED
			
			if direction != 0:
				sprite.flip_h = (direction < 0) 
				$Hitbox.scale.x = direction
				ledge_check.position.x = abs(ledge_check.position.x) * direction
		
		if is_on_floor() and not is_preparing_jump and not is_dropping and not is_attacking:
			if target.global_position.distance_to(global_position) < 45.0:
				perform_attack()
			elif target.global_position.y > global_position.y + 50 and abs(target.global_position.x - global_position.x) < 50:
				drop_through_platform()
			elif target.is_on_floor() and target.global_position.y < global_position.y - 50 and abs(target.global_position.x - global_position.x) < 50:
				execute_delayed_jump()
			else:
				var is_at_edge = not ledge_check.is_colliding()
				var is_hitting_wall = is_on_wall()
				var target_is_higher = target.global_position.y < (global_position.y - 30)
				
				if (is_at_edge or is_hitting_wall) and target_is_higher:
					velocity.y = JUMP_VELOCITY
				
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Global Animation Handling 
	if not is_attacking:
		if is_on_floor():
			if velocity.x != 0:
				sprite.play("Running")
			else:
				sprite.play("Idle")
		else:
			if velocity.y < 0:
				sprite.play("Jump")
			else:
				sprite.play("Falling")

	move_and_slide()


func perform_attack() -> void:
	is_attacking = true
	velocity.x = 0 
	
	# Create a token to track this specific attack
	attack_token += 1
	var my_token = attack_token
	
	# Switch to the Attack frames and let the AnimationPlayer drive
	sprite.animation = "Attack"
	sprite.stop() 
	
	if has_node("Animation"):
		$Animation.play("enemyattack")
		await $Animation.animation_finished
	else:
		await get_tree().create_timer(0.5).timeout 
		
	# If the token changed (meaning a stagger interrupted this), abort finishing the attack
	if my_token != attack_token or is_staggered:
		return
		
	is_attacking = false


func drop_through_platform() -> void:
	is_dropping = true
	set_collision_mask_value(PLATFORM_LAYER, false)
	await get_tree().create_timer(0.2).timeout
	set_collision_mask_value(PLATFORM_LAYER, true)
	is_dropping = false


func execute_delayed_jump() -> void:
	is_preparing_jump = true
	await get_tree().create_timer(0.8).timeout
	if is_inside_tree() and is_on_floor():
		velocity.y = JUMP_VELOCITY
	is_preparing_jump = false


func get_closest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	var closest = null
	
	# Enforce the maximum detection range limit
	var shortest_dist = detection_range 
	
	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < shortest_dist:
			shortest_dist = dist
			closest = p
			
	return closest


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Enemy hit ", body.name, "!")
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)


func take_damage(amount: int, hit_type: String = "melee") -> void:
	health -= amount
	print("Enemy took ", amount, " damage! Health is now: ", health)
	
	flash_red()
	
	match hit_type:
		"melee":
			hit_sound_melee.play()
		"arrow":
			hit_sound_arrow.play()
	
	if health <= 0:
		print("Enemy defeated!")
		set_physics_process(false) 
		$CollisionShape2D.set_deferred("disabled", true)
		$Hitbox/CollisionShape2D.set_deferred("disabled", true)
		sprite.play("Death")
		await sprite.animation_finished
		queue_free()
		return
		
	if can_be_staggered:
		apply_stagger()


func flash_red() -> void:
	sprite.modulate = Color(1.0, 0.25, 0.25)
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)


func apply_stagger() -> void:
	is_staggered = true
	can_be_staggered = false
	
	# Immediately cancel attack and stop the animation player
	attack_token += 1
	is_attacking = false
	if has_node("Animation"):
		$Animation.stop()
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	sprite.play("Idle")
	
	await get_tree().create_timer(STAGGER_DURATION).timeout
	is_staggered = false
	
	await get_tree().create_timer(STAGGER_COOLDOWN).timeout
	can_be_staggered = true
