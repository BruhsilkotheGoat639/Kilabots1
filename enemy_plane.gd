extends CharacterBody2D

const SPEED = 50.0
const EXPLOSION_DAMAGE = 10.0
const TURN_SPEED = 2.5 # How fast it steers. Lower = wider turns, Higher = tighter turns

@export var max_health: float = 60.0
@export var enemy_bullet: PackedScene

@onready var muzzle = $Muzzle
@onready var anim = $Animation
var health: float
var target: Node2D
var can_shoot := true

func _ready() -> void:
	health = max_health
	target = get_tree().get_first_node_in_group("player_plane")
	
	# Start by instantly facing the player when spawned
	if target and is_instance_valid(target):
		look_at(target.global_position)
		
	start_burst_fire()

func _physics_process(delta: float) -> void:
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
	while true:
		await get_tree().create_timer(2.5).timeout
		
		if target and is_instance_valid(target):
			for i in 3:
				shoot()
				await get_tree().create_timer(0.15).timeout 

func shoot() -> void:
	if not enemy_bullet:
		return
		
	var bullet = enemy_bullet.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	# Shoot straight ahead based on the plane's current smooth rotation
	bullet.direction = Vector2.RIGHT.rotated(rotation)

func _on_kamikaze_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_plane"):
		if body.has_method("take_damage"):
			body.take_damage(EXPLOSION_DAMAGE)
		queue_free() 

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		queue_free()
