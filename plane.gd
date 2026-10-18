extends CharacterBody2D

const SPEED = 400.0
const FIRE_RATE = 0.1

@export var bullet_scene: PackedScene
@onready var muzzle: Marker2D = $Muzzle
@onready var anim: AnimatedSprite2D = $Animation

var fire_timer := 0.0
var health := 100.0 # Float to allow 0.5 damage

func _ready() -> void:
	if anim:
		anim.play("Flying")

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	
	var is_hacking = get_viewport().gui_get_focus_owner() is TextEdit
	
	if not is_hacking:
		direction = Input.get_vector("P2Left", "P2Right", "P2Jump", "P2Down")
		
	velocity = direction * SPEED
	move_and_slide()
	
	look_at(get_global_mouse_position())
	
	fire_timer -= delta
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if fire_timer <= 0.0:
			shoot()
			fire_timer = FIRE_RATE

func shoot() -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_transform = muzzle.global_transform

func take_damage(amount: float) -> void:
	health -= amount
	print("Player Plane HP: ", health)
	
	if health <= 0:
		print("Plane Destroyed - Game Over!")
		queue_free()
		# Add your game over logic here (e.g., get_tree().reload_current_scene())
