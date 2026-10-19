extends CharacterBody2D

enum STATE {
	IDLE,
	JUMP,
	FALL,
	AIM, 
	ATTACK,
	HURT,
	DIE,
}

const WALK_VELOCITY := 105.0
const JUMP_VELOCITY := -450
const GRAVITY := 1000.0
const DOUBLE_TAP_WINDOW := 0.25 
const PLATFORM_LAYER := 2 

var active_state := STATE.IDLE
var facing_direction := 1.0 
var last_down_time := 0.0
var max_health := 100
var health := 100

@export var arrow_scene: PackedScene 

@onready var pivot: Marker2D = $Pivot
@onready var muzzle: Marker2D = $Pivot/Muzzle
@onready var anim: AnimatedSprite2D = $Animation
@onready var health_bar: ProgressBar = $Healthbar/bar
@onready var hurt_sound =  $Hurtsound # Targets the ProgressBar inside your Healthbar node

func _ready() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("P2Left", "P2Right")
	
	
	if direction != 0 and active_state != STATE.ATTACK:
		facing_direction = sign(direction)
		pivot.scale.x = facing_direction
		
		anim.flip_h = (facing_direction < 0)
	
	match active_state:
		STATE.IDLE:
			velocity.x = direction * WALK_VELOCITY
			
			if Input.is_action_just_pressed("P2Down"):
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_down_time <= DOUBLE_TAP_WINDOW:
					drop_through_platform()
				last_down_time = current_time
			
			if Input.is_action_pressed("P2Aim"): 
				switch_state(STATE.AIM)
			elif Input.is_action_just_pressed("P2Jump"):
				switch_state(STATE.JUMP)
			elif not is_on_floor():
				switch_state(STATE.FALL)
		
		STATE.JUMP:
			velocity.x = direction * WALK_VELOCITY
			velocity.y = JUMP_VELOCITY
			
			if Input.is_action_pressed("P2Aim"):
				switch_state(STATE.AIM)
			else:
				switch_state(STATE.FALL)
		
		STATE.FALL:
			velocity.x = direction * WALK_VELOCITY
			velocity.y += GRAVITY * delta
			
			if Input.is_action_pressed("P2Aim"):
				switch_state(STATE.AIM)
			elif is_on_floor():
				switch_state(STATE.IDLE)
				
		STATE.AIM:
			
			velocity.x = move_toward(velocity.x, 0, WALK_VELOCITY * delta * 10)
			
			if not is_on_floor():
				velocity.y += GRAVITY * delta
				
			# If they press attack while holding aim, shoot
			if Input.is_action_just_pressed("P2Attack"):
				switch_state(STATE.ATTACK)
			# If they let go of the aim button, go back to moving
			elif not Input.is_action_pressed("P2Aim"):
				if is_on_floor():
					switch_state(STATE.IDLE)
				else:
					switch_state(STATE.FALL)
				
		STATE.ATTACK:
			velocity.x = move_toward(velocity.x, 0, WALK_VELOCITY * delta * 10)
			if not is_on_floor():
				velocity.y += GRAVITY * delta

	
	if is_on_floor():
		if active_state == STATE.AIM or active_state == STATE.ATTACK:
			anim.play("Aiming_Shoot")
		elif direction != 0:
			anim.play("Walk")
		else:
			anim.play("Idle")
	else:
		if active_state == STATE.AIM or active_state == STATE.ATTACK:
			anim.play("Aiming_Shoot")
		elif velocity.y < 0:
			anim.play("Jump")
		else:
			anim.play("Falling")
	# --------------------------------------
			
	move_and_slide()


func switch_state(to_state: STATE) -> void:
	if active_state == STATE.ATTACK and to_state != STATE.IDLE and to_state != STATE.FALL and to_state != STATE.AIM:
		return
		
	active_state = to_state
	
	match active_state:
		STATE.IDLE:
			pass
		STATE.JUMP:
			pass
		STATE.FALL:
			pass
		STATE.AIM:
			pass
		STATE.ATTACK:
			shoot_arrow()


func drop_through_platform() -> void:
	set_collision_mask_value(PLATFORM_LAYER, false)
	switch_state(STATE.FALL)
	await get_tree().create_timer(0.15).timeout
	set_collision_mask_value(PLATFORM_LAYER, true)


func shoot_arrow() -> void:
	if arrow_scene:
		var arrow = arrow_scene.instantiate()
		get_tree().current_scene.add_child(arrow)
		arrow.global_position = muzzle.global_position
		
		# Get 8-directional input
		var input_x = sign(Input.get_axis("P2Left", "P2Right"))
		var input_y = sign(Input.get_axis("P2Jump", "P2Down"))
		var aim_dir = Vector2(input_x, input_y)
		
		if aim_dir == Vector2.ZERO:
			aim_dir = Vector2(facing_direction, 0)
		else:
			aim_dir = aim_dir.normalized()
			
		arrow.direction = aim_dir
		arrow.rotation = aim_dir.angle()
			
	# Cooldown timer
	await get_tree().create_timer(0.3).timeout
	
	if Input.is_action_pressed("P2Aim"):
		switch_state(STATE.AIM)
	elif is_on_floor():
		switch_state(STATE.IDLE)
	else:
		switch_state(STATE.FALL)


func take_damage(amount: int) -> void:
	health -= amount
	hurt_sound.play()
	DamageIndicator.spawn_damage(global_position, amount, true)
	health = max(health, 0) # Keeps health from going below 0
	
	# --- UPDATE HEALTH BAR ---
	if health_bar:
		health_bar.value = health
	# -------------------------
	
	print(name, " took damage! Health is now: ", health)#[cite: 5]
	
	if health <= 0:
		print(name, " died!")
		remove_from_group("player")
		set_physics_process(false) 
		$CollisionShape2D.set_deferred("disabled", true)
		if health_bar:
			health_bar.visible = false # Hides the bar on death
		anim.play("Death")
		await anim.animation_finished
		queue_free()
