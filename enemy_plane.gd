extends CharacterBody2D

const SPEED = 50.0
const EXPLOSION_DAMAGE = 10.0
const TURN_SPEED = 2.5 # How fast it steers. Lower = wider turns, Higher = tighter turns

@export var max_health: float = 60.0
@export var enemy_bullet: PackedScene

@onready var muzzle = $Muzzle
@onready var anim = $Animation
@onready var explosion_sound: AudioStreamPlayer2D = $ExplosionSound
@onready var hit_sound : AudioStreamPlayer2D = $WispHit

var health: float
var target: Node2D
var can_shoot := true
var is_exploding := false

func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player_plane")
	if not target:
		target = get_tree().get_first_node_in_group("player")
	
	# Start by instantly facing the player when spawned
	if target and is_instance_valid(target):
		look_at(target.global_position)
		
	start_burst_fire()

func _physics_process(delta: float) -> void:
	if is_exploding:
		return
		
	if target and is_instance_valid(target):
		# 1. Find the angle where the player is
		var target_angle = global_position.direction_to(target.global_position).angle()
		
		# 2. Smoothly steer the plane's rotation toward the player over time
		rotation = lerp_angle(rotation, target_angle, TURN_SPEED * delta)
		
		# 3. Always fly straight "forward" based on where the plane is currently facing
		velocity = Vector2.RIGHT.rotated(rotation) * SPEED
		move_and_slide()
		
	anim.play("Enemy_plane")

func start_burst_fire() -> void:
	while not is_exploding:
		await get_tree().create_timer(2.5).timeout
		
		if is_exploding:
			break
			
		if can_shoot and target and is_instance_valid(target):
			for i in 3:
				if is_exploding:
					break
				shoot()
				await get_tree().create_timer(0.15).timeout

func shoot() -> void:
	if not enemy_bullet or is_exploding:
		return
		
	var bullet = enemy_bullet.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	# Shoot straight ahead based on the plane's current smooth rotation
	bullet.direction = Vector2.RIGHT.rotated(rotation)

func _on_kamikaze_hitbox_body_entered(body: Node2D) -> void:
	if is_exploding:
		return
		
	if body.is_in_group("player_plane") or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(EXPLOSION_DAMAGE)
		explode()

func take_damage(amount: float) -> void:
	if is_exploding:
		return
		
	health -= amount
	hit_sound.play()
	DamageIndicator.spawn_damage(global_position, int(max(1, amount)), false)
	if health <= 0:
		queue_free() # Change to explode() if you also want the sound when shot down!

func explode() -> void:
	is_exploding = true
	can_shoot = false
	
	# Hide the plane and turn off collisions so it can't hit the player twice
	hide()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	if has_node("KamikazeHitbox"):
		$KamikazeHitbox.set_deferred("monitoring", false)
		
	# Play the explosion sound and wait for it to finish before deleting the node
	if explosion_sound and explosion_sound.stream:
		explosion_sound.pitch_scale = randf_range(0.9, 1.1)
		explosion_sound.play()
		await explosion_sound.finished
		
	queue_free()
