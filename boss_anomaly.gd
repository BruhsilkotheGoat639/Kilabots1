extends CharacterBody2D

const SPEED = 50.0
const FLOAT_ACCELERATION = 5.0
const HOVER_BOB_SPEED = 4.0
const HOVER_BOB_AMPLITUDE = 8.0
const HOVER_HEIGHT_OFFSET = -25.0

const MAX_HEALTH = 500
const MELEE_DAMAGE = 30
const MELEE_RANGE = 100.0
const RANGED_MIN_DISTANCE = 150.0
const BASIC_ATTACK_COOLDOWN = 5.0

@export var detection_range: float = 350.0
@export var boss_projectile_scene: PackedScene
@export var boss_time_stop_projectile_scene: PackedScene

@onready var time_stop_sound : AudioStreamPlayer2D = $TimeStopSound

var health = MAX_HEALTH
var current_phase = 1
var is_doing_mechanic = false
var can_basic_attack = true
var phase_skill_ready = false
var melee_target: Node2D = null
var hover_time: float = 0.0
var base_sprite_y: float = 0.0

@onready var anim: AnimatedSprite2D = $Animation
@onready var anim_player: AnimationPlayer = $Animations
@onready var attack_timer: Timer = $AttackTimer
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hit_sound_melee: AudioStreamPlayer2D = $HitSoundMelee
@onready var hit_sound_arrow: AudioStreamPlayer2D = $HitSoundArrow
@onready var projectile_throw: AudioStreamPlayer2D = $Projectilethrow
@onready var teleport_sound: AudioStreamPlayer2D = $Teleport

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("boss")
	
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	base_sprite_y = anim.position.y
	
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		
	attack_timer.one_shot = true
	if not attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start(4.0)
	print("[Boss - Phase ", current_phase, "] BossAnomaly initialized with ", health, " HP.")

func _physics_process(delta: float) -> void:
	hover_time += delta
	anim.position.y = base_sprite_y + sin(hover_time * HOVER_BOB_SPEED) * HOVER_BOB_AMPLITUDE

	# Lock movement while performing an attack or phase mechanic
	if is_doing_mechanic:
		velocity = velocity.lerp(Vector2.ZERO, FLOAT_ACCELERATION * 2.0 * delta)
		
		if is_instance_valid(melee_target):
			var dir_to_target = (melee_target.global_position - global_position).normalized()
			hitbox.rotation = dir_to_target.angle()
			if dir_to_target.x != 0:
				anim.flip_h = (dir_to_target.x < 0)
				
		move_and_slide()
		return
		
	# TOP PRIORITY: Execute queued Phase Mechanic (Phase 2 & Phase 3 only)
	if phase_skill_ready:
		phase_skill_ready = false
		execute_phase_mechanic()
		return
		
	var target = get_nearest_player()
	
	if target:
		var dist = global_position.distance_to(target.global_position)
		var hover_target_pos = target.global_position + Vector2(0, HOVER_HEIGHT_OFFSET)
		var direction = (hover_target_pos - global_position).normalized()
		
		if direction.x != 0:
			anim.flip_h = (direction.x < 0)
			
		# SECOND PRIORITY: Basic Close or Ranged Attack
		if can_basic_attack:
			if dist <= MELEE_RANGE:
				perform_close_attack(target)
				return
			elif dist >= RANGED_MIN_DISTANCE:
				perform_ranged_attack(target)
				return
				
		# Smoothly float toward the player
		velocity = velocity.lerp(direction * SPEED, FLOAT_ACCELERATION * delta)
		anim.play("Idle")
	else:
		velocity = velocity.lerp(Vector2.ZERO, FLOAT_ACCELERATION * delta)
		if get_alive_players().size() > 0:
			teleport_to_random_player()
		else:
			anim.play("Idle")
		
	move_and_slide()


# --- PHASE MECHANIC QUEUE & EXECUTION ---
func _on_attack_timer_timeout() -> void:
	if current_phase > 1:
		print("[Boss Timer] Special Phase ", current_phase, " ability is now READY!")
		phase_skill_ready = true
	else:
		# Phase 1 has no timer-based spells, just keep attacking close/ranged
		attack_timer.start(4.0)


func execute_phase_mechanic() -> void:
	match current_phase:
		2:
			cast_temporal_rewind()
		3:
			cast_time_stop_barrage()


func cast_temporal_rewind() -> void:
	is_doing_mechanic = true
	
	var saved_pos = global_position
	var saved_health = health
	print("[Boss - Phase 2 Mechanic] Temporal Anchor set at ", saved_pos, " (Saved HP: ", saved_health, ")")
	
	anim.modulate = Color(0.3, 1.0, 1.0)
	is_doing_mechanic = false
	
	await get_tree().create_timer(3.0).timeout
	if health <= 0:
		return
		
	while is_doing_mechanic and health > 0:
		await get_tree().process_frame
	if health <= 0:
		return
		
	is_doing_mechanic = true
	var tween = create_tween()
	tween.tween_property(self, "global_position", saved_pos, 0.25)
	await tween.finished
	
	if health < saved_health:
		var healed = int((saved_health - health) * 0.5)
		health += healed
		print("[Boss - Phase 2 Mechanic] REWINDING TIME! Recovered ", healed, " HP (Current HP: ", health, ")")
	else:
		print("[Boss - Phase 2 Mechanic] REWINDING TIME! Snapped back to saved position.")
		
	anim.modulate = Color.WHITE
	is_doing_mechanic = false
	attack_timer.start(5.0)


func cast_time_stop_barrage() -> void:
	is_doing_mechanic = true
	get_tree().paused = true
	time_stop_sound.play()
	
	var target = get_nearest_player()
	if not target:
		var players = get_alive_players()
		if not players.is_empty():
			target = players.pick_random()
			
	var target_name = target.name if is_instance_valid(target) else "None"
	print("[Boss - Phase 3 Mechanic] TIME STOP BARRAGE activated! Freezing world and surrounding ", target_name)
	
	if is_instance_valid(target):
		var ring_radius := 500.0
		var num_projectiles := 6
		
		for i in range(num_projectiles):
			var angle = (TAU / num_projectiles) * i
			var spawn_pos = target.global_position + Vector2(cos(angle), sin(angle)) * ring_radius
			projectile_throw.play()
			
			global_position = spawn_pos
			anim.flip_h = (target.global_position.x < global_position.x)
			anim.play("Throw")
			print("[Boss - Phase 3 Mechanic] Placed Time-Stop projectile ", i + 1, "/", num_projectiles)
			
			if boss_projectile_scene:
				var proj = boss_time_stop_projectile_scene.instantiate()
				get_tree().current_scene.add_child(proj)
				proj.global_position = spawn_pos
				var aim_dir = (target.global_position - spawn_pos).normalized()
				proj.direction = aim_dir
				proj.rotation = aim_dir.angle()
				
			await get_tree().create_timer(0.45, true, false, true).timeout
			
	get_tree().paused = false
	print("[Boss - Phase 3 Mechanic] Time resumes! All projectiles launched.")
	is_doing_mechanic = false
	attack_timer.start(10.5)


# --- CLOSE & RANGED BASIC ATTACKS ---
func perform_close_attack(target: Node2D) -> void:
	is_doing_mechanic = true
	can_basic_attack = false
	velocity = Vector2.ZERO
	
	var target_name = target.name if is_instance_valid(target) else "Unknown"
	print("[Boss - Phase ", current_phase, "] Attack: Close-Range Melee ('attack' AnimationPlayer) targeting ", target_name)
	
	melee_target = target
	
	anim.animation = "Attack"
	anim.stop()
	
	anim_player.play("attack")
	await anim_player.animation_finished
	
	melee_target = null
	is_doing_mechanic = false
	
	await get_tree().create_timer(BASIC_ATTACK_COOLDOWN).timeout
	can_basic_attack = true


func perform_ranged_attack(target: Node2D) -> void:
	is_doing_mechanic = true
	can_basic_attack = false
	velocity = Vector2.ZERO
	
	var target_name = target.name if is_instance_valid(target) else "Unknown"
	print("[Boss - Phase ", current_phase, "] Attack: Ranged Projectile ('Throw' animation) targeting ", target_name)
	
	if is_instance_valid(target):
		anim.flip_h = (target.global_position.x < global_position.x)
		
	anim.play("Throw")
	await get_tree().create_timer(0.4).timeout
	
	if is_instance_valid(target) and boss_projectile_scene:
		var proj = boss_projectile_scene.instantiate()
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position
		var aim_dir = (target.global_position - global_position).normalized()
		proj.direction = aim_dir
		proj.rotation = aim_dir.angle()
		
	await get_tree().create_timer(0.3).timeout
	is_doing_mechanic = false
	
	await get_tree().create_timer(BASIC_ATTACK_COOLDOWN).timeout
	can_basic_attack = true


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		print("[Boss - Phase ", current_phase, "] Close-Range Hitbox connected with ", body.name, " for ", MELEE_DAMAGE, " damage!")
		body.take_damage(MELEE_DAMAGE)


# --- TARGETING & RANDOM TELEPORT ---
func get_nearest_player() -> Node2D:
	var players = get_alive_players()
	var nearest: Node2D = null
	var min_dist := detection_range
	
	for p in players:
		var dist = global_position.distance_to(p.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = p
	return nearest


func get_alive_players() -> Array[Node2D]:
	var valid_players: Array[Node2D] = []
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			valid_players.append(p)
	return valid_players


func teleport_to_random_player() -> void:
	var players = get_alive_players()
	if players.is_empty():
		return
		
	teleport_sound.play()
		
	is_doing_mechanic = true
	var random_target: Node2D = players.pick_random()
	print("[Boss - Phase ", current_phase, "] Lost target! Teleporting to random player: ", random_target.name)
	
	for i in range(2):
		anim.modulate.a = 0.25
		await get_tree().create_timer(0.1, true, false, true).timeout
		anim.modulate.a = 1.0
		await get_tree().create_timer(0.1, true, false, true).timeout
		
	if is_instance_valid(random_target):
		var side = -1.0 if randf() < 0.5 else 1.0
		global_position = random_target.global_position + Vector2(side * 60.0, HOVER_HEIGHT_OFFSET)
		anim.flip_h = (random_target.global_position.x < global_position.x)
		
	await get_tree().create_timer(0.2).timeout
	is_doing_mechanic = false


func take_damage(amount: int, hit_type: String = "melee") -> void:
	health -= amount
	DamageIndicator.spawn_damage(global_position, amount, false)
	print("[Boss - Phase ", current_phase, "] Took ", amount, " damage! Remaining HP: ", health, "/", MAX_HEALTH)
	
	var return_color = Color(0.3, 1.0, 1.0) if current_phase == 2 else Color.WHITE
	anim.modulate = Color(1.0, 0.25, 0.25)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(anim, "modulate", return_color, 0.15)
	
	match hit_type:
		"melee":
			hit_sound_melee.play()
		"arrow":
			hit_sound_arrow.play()
			
	check_phase_transition()

	
	if health <= 0:
		die()


func check_phase_transition() -> void:
	if health <= 300 and current_phase == 1:
		current_phase = 2
		phase_skill_ready = true
		print("==================================================")
		print("   BOSS ENTERED PHASE 2: TEMPORAL REWIND (HP: ", health, ")")
		print("==================================================")
	elif health <= 125 and current_phase == 2:
			current_phase = 3
			phase_skill_ready = true
			print("==================================================")
			print("   BOSS ENTERED PHASE 3: SHATTERED REALITY (HP: ", health, ")")
			print("==================================================")


func die() -> void:
	print("[Boss - Phase ", current_phase, "] Boss defeated!")
	is_doing_mechanic = true
	melee_target = null
	attack_timer.stop()
	anim_player.stop()
	hitbox_shape.set_deferred("disabled", true)
	get_tree().paused = false
	anim.play("Death")
	await get_tree().create_timer(1.0).timeout
	queue_free()
