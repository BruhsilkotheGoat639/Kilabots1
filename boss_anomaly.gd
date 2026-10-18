extends CharacterBody2D

const SPEED = 140.0
const MAX_HEALTH = 500
const CONTACT_DAMAGE = 15

@export var chronosphere_scene: PackedScene
@export var boss_projectile_scene: PackedScene # Drag your enemy_arrow.tscn here!

var health = MAX_HEALTH
var current_phase = 1
var is_doing_mechanic = false

@onready var anim = $Animation
@onready var attack_timer = $AttackTimer

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start(3.5)

func _physics_process(_delta: float) -> void:
	if is_doing_mechanic:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var target = get_nearest_player()
	if target:
		var direction = (target.global_position - global_position).normalized()
		velocity = direction * SPEED
		
		if direction.x != 0:
			anim.flip_h = (direction.x < 0)
			
		anim.play("Walk")
	else:
		velocity = Vector2.ZERO
		anim.play("Idle")
		
	move_and_slide()


func get_nearest_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	var nearest: Node2D = null
	var min_dist := INF
	
	for p in players:
		if is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = p
	return nearest


func _on_attack_timer_timeout() -> void:
	if is_doing_mechanic:
		return
		
	match current_phase:
		1:
			cast_chronosphere_and_blink()
		2:
			cast_temporal_rewind()
		3:
			cast_time_stop_barrage()


# --- PHASE 1: CHRONOSPHERE + STUTTER-STEP TELEPORT ---
func cast_chronosphere_and_blink() -> void:
	is_doing_mechanic = true
	var target = get_nearest_player()
	
	if target and chronosphere_scene:
		var bubble = chronosphere_scene.instantiate()
		get_tree().current_scene.add_child(bubble)
		bubble.global_position = target.global_position
		
	# Stutter-step flicker before teleporting near the player
	for i in range(3):
		anim.modulate.a = 0.3
		await get_tree().create_timer(0.1, true, false, true).timeout
		anim.modulate.a = 1.0
		await get_tree().create_timer(0.1, true, false, true).timeout
		
	if is_instance_valid(target):
		var offset_x = -60.0 if target.global_position.x > global_position.x else 60.0
		global_position = target.global_position + Vector2(offset_x, -10)
		anim.play("Attack")
		
	await get_tree().create_timer(0.6).timeout
	is_doing_mechanic = false
	attack_timer.start(4.0)


# --- PHASE 2: TEMPORAL REWIND ---
func cast_temporal_rewind() -> void:
	is_doing_mechanic = true
	
	# Save past state
	var saved_pos = global_position
	var saved_health = health
	
	# Glow cyan to telegraph that the boss marked its timeline
	anim.modulate = Color(0.3, 1.0, 1.0)
	
	# Spawn a Chronosphere too if available
	var target = get_nearest_player()
	if target and chronosphere_scene:
		var bubble = chronosphere_scene.instantiate()
		get_tree().current_scene.add_child(bubble)
		bubble.global_position = target.global_position
		
	is_doing_mechanic = false
	
	# Let the boss chase and fight normally for 3 seconds
	await get_tree().create_timer(3.0).timeout
	if health <= 0:
		return
		
	# Rewind back to saved position and recover 50% of damage taken during the window
	is_doing_mechanic = true
	print("REWINDS TIME!")
	var tween = create_tween()
	tween.tween_property(self, "global_position", saved_pos, 0.25)
	await tween.finished
	
	if health < saved_health:
		health += int((saved_health - health) * 0.5)
		print("Boss rewound health to: ", health)
		
	anim.modulate = Color.WHITE
	is_doing_mechanic = false
	attack_timer.start(4.5)


# --- PHASE 3: TIME STOP KNIFE/ARROW BARRAGE ---
func cast_time_stop_barrage() -> void:
	is_doing_mechanic = true
	print("TIME IS STOPPED!")
	
	get_tree().paused = true
	var target = get_nearest_player()
	
	if is_instance_valid(target):
		var ring_radius := 250.0
		var num_projectiles := 6
		
		# Teleport in a circle around the frozen player, placing projectiles in mid-air
		for i in range(num_projectiles):
			var angle = (TAU / num_projectiles) * i
			var spawn_pos = target.global_position + Vector2(cos(angle), sin(angle)) * ring_radius
			
			# Boss teleports to each spot to "place" the projectile
			global_position = spawn_pos
			anim.flip_h = (target.global_position.x < global_position.x)
			anim.play("Attack")
			
			if boss_projectile_scene:
				var proj = boss_projectile_scene.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.global_position = spawn_pos
				var aim_dir = (target.global_position - spawn_pos).normalized()
				proj.direction = aim_dir
				proj.rotation = aim_dir.angle()
				
			await get_tree().create_timer(0.45, true, false, true).timeout
			
	# Unpause time — all 6 projectiles immediately launch at the player!
	get_tree().paused = false
	print("Time resumes!")
	
	is_doing_mechanic = false
	attack_timer.start(5.0)


func take_damage(amount: int) -> void:
	health -= amount
	print("Boss HP: ", health)
	
	anim.modulate = Color(1.0, 0.25, 0.25)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)
	
	check_phase_transition()
	
	if health <= 0:
		die()


func check_phase_transition() -> void:
	if health <= 300 and current_phase == 1:
		current_phase = 2
		print("Phase 2 Initiated: TEMPORAL REWIND")
	elif health <= 125 and current_phase == 2:
		current_phase = 3
		print("Phase 3 Initiated: SHATTERED REALITY")


func die() -> void:
	is_doing_mechanic = true
	attack_timer.stop()
	get_tree().paused = false
	anim.play("Death")
	await anim.animation_finished
	queue_free()
