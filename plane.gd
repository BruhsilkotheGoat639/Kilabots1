extends CharacterBody2D

const SPEED = 400.0
const HACKED_SPEED_MULTIPLIER = 0.15 # Moves at 40% speed while hacked
const FIRE_RATE = 0.1
const MAX_HEALTH = 100.0

@export var bullet_scene: PackedScene
@onready var muzzle: Marker2D = $Muzzle
@onready var anim: AnimatedSprite2D = $Animation
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var plane_hit: AudioStreamPlayer2D = $PlaneHit

var fire_timer := 0.0
var health := MAX_HEALTH
var is_hacked := false # Resets automatically on scene reload!

func _ready() -> void:
	add_to_group("player")
	if anim:
		anim.play("Flying")

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("P2Left", "P2Right", "P2Jump", "P2Down")
	
	# Use the explicit is_hacked boolean instead of checking viewport focus
	var current_speed = SPEED * HACKED_SPEED_MULTIPLIER if is_hacked else SPEED
		
	velocity = direction * current_speed
	move_and_slide()
	
	look_at(get_global_mouse_position())
	
	fire_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if fire_timer <= 0.0:
			shoot()
			fire_timer = FIRE_RATE

func set_hacked(hacked: bool) -> void:
	is_hacked = hacked

func shoot() -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = muzzle.global_transform
	
	if shoot_sound:
		shoot_sound.pitch_scale = randf_range(0.92, 1.08)
		shoot_sound.play()

func heal(amount: float) -> void:
	health = min(health + amount, MAX_HEALTH)
	print("Hack completed! Plane healed +", amount, " HP. Current HP: ", health)

func take_damage(amount: float) -> void:
	health -= amount
	ScoreManager.subtract_score(1)
	plane_hit.play()
	DamageIndicator.spawn_damage(global_position, int(max(1, amount)), true)
	print("Player Plane HP: ", health)
	
	if health <= 0:
		print("Plane Destroyed - Game Over!")
		remove_from_group("player")
		queue_free()
