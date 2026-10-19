extends ProgressBar

@onready var enemy: CharacterBody2D = get_parent()
var last_health: float = 100.0
var hide_timer: Timer
var current_tween: Tween

func _ready() -> void:
	# Start completely transparent
	modulate.a = 0.0
	
	if enemy and "health" in enemy:
		max_value = enemy.health
		last_health = enemy.health
		value = enemy.health
		
	# Timer to trigger the fade out after 2 seconds
	hide_timer = Timer.new()
	hide_timer.one_shot = true
	hide_timer.wait_time = 2.0
	hide_timer.timeout.connect(_fade_out)
	add_child(hide_timer)

func _process(_delta: float) -> void:
	if not is_instance_valid(enemy):
		return
		
	if "health" in enemy:
		value = enemy.health
		
		# If health dropped, trigger fade in and restart the 2-second timer
		if enemy.health < last_health:
			_fade_in()
			hide_timer.start(2.0)
			
		last_health = enemy.health

func _fade_in() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 1.0, 0.2) # Fades in over 0.2 seconds

func _fade_out() -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 0.0, 0.4) # Fades out over 0.4 seconds
