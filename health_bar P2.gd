extends CharacterBody2D
var max_health := 150
var health := 150
@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health

func take_damage(amount: int) -> void:
	health -= amount
	health = max(health, 0)
	
	if health_bar:
		health_bar.value = health
	
