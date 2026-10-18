extends CharacterBody2D

enum STATE {
	IDLE,
	JUMP,
	FALL,
	ATTACK,
	HURT,
	DIE,
}

const WALK_VELOCITY := 90.0
const JUMP_VELOCITY := -450
const GRAVITY := 1000.0

const DOUBLE_TAP_WINDOW := 0.25 
var last_down_time := 0.0
const PLATFORM_LAYER := 2 

var health = 150
var active_state := STATE.IDLE
var facing_direction := 1.0 
var damage_amount = 30

@onready var pivot: Marker2D = $Pivot
@onready var hitbox_shape: CollisionShape2D = $Pivot/Hitbox/CollisionShape2D
@onready var hitbox: Area2D = $Pivot/Hitbox
@onready var anim: AnimatedSprite2D = $Animation
@onready var attack_anim_player: AnimationPlayer = $AttackAnimation # --- NEW: Reference to the AnimationPlayer ---

func _ready() -> void:
	hitbox_shape.disabled = true
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("P1Left", "P1Right")
	
	if direction != 0 and active_state != STATE.ATTACK:
		facing_direction = sign(direction)
		pivot.scale.x = facing_direction
		anim.flip_h = (facing_direction < 0)
	
	match active_state:
		STATE.IDLE:
			velocity.x = direction * WALK_VELOCITY
			
			if Input.is_action_just_pressed("P1Down"): 
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_down_time <= DOUBLE_TAP_WINDOW:
					drop_through_platform()
				last_down_time = current_time
			
			if Input.is_action_just_pressed("P1Attack"): 
				switch_state(STATE.ATTACK)
			elif Input.is_action_just_pressed("P1Jump"):
				switch_state(STATE.JUMP)
			elif not is_on_floor():
				switch_state(STATE.FALL)
		
		STATE.JUMP:
			velocity.x = direction * WALK_VELOCITY
			velocity.y = JUMP_VELOCITY
			
			if Input.is_action_just_pressed("P1Attack"):
				switch_state(STATE.ATTACK)
			else:
				switch_state(STATE.FALL)
		
		STATE.FALL:
			velocity.x = direction * WALK_VELOCITY
			velocity.y += GRAVITY * delta
			
			if Input.is_action_just_pressed("P1Attack"):
				switch_state(STATE.ATTACK)
			elif is_on_floor():
				switch_state(STATE.IDLE)
				
		STATE.ATTACK:
			velocity.x = move_toward(velocity.x, 0, WALK_VELOCITY * delta * 10)
			
			if not is_on_floor():
				velocity.y += GRAVITY * delta
				
	if active_state != STATE.ATTACK:
		if is_on_floor():
			if direction != 0:
				anim.play("Walk") 
			else:
				anim.play("Idle")
		else:
			if velocity.y < 0:
				anim.play("Jump")
			else:
				anim.play("Fall")
			
	move_and_slide()


func switch_state(to_state: STATE) -> void:
	if active_state == STATE.ATTACK and to_state != STATE.IDLE and to_state != STATE.FALL:
		return
		
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			pass
		STATE.JUMP:
			pass
		STATE.FALL:
			pass
		STATE.ATTACK:
			perform_attack()


func drop_through_platform() -> void:
	set_collision_mask_value(PLATFORM_LAYER, false)
	switch_state(STATE.FALL)
	await get_tree().create_timer(0.15).timeout
	set_collision_mask_value(PLATFORM_LAYER, true)


# --- UPDATED: Delegate hitbox and frame control entirely to the AnimationPlayer ---
func perform_attack() -> void:
	# Prepare the AnimatedSprite2D and yield control
	anim.animation = "Attack"
	anim.stop()
	health += 5
	print("Player Lifesteal 5 hp!")
	
	# Play the AnimationPlayer timeline
	attack_anim_player.play("AttackAnimation")
	await attack_anim_player.animation_finished
	
	if is_on_floor():
		switch_state(STATE.IDLE)
	else:
		switch_state(STATE.FALL)
# ----------------------------------------------------------------------------------


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			print("Hit enemy for ", damage_amount, " damage!")



func take_damage(amount: int) -> void:
	health -= amount
	print(name, " took damage! Health is now: ", health)
	
	if health <= 0:
		print(name, " died!")
		remove_from_group("player")
		set_physics_process(false) 
		$CollisionShape2D.set_deferred("disabled", true)
		$Pivot/Hitbox/CollisionShape2D.set_deferred("disabled", true)
		anim.play("Death")
		await anim.animation_finished
		queue_free()
