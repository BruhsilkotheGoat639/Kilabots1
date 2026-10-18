extends Node2D
@onready var camera = $DynamicCamera
@onready var player1 = $Players/P1
@onready var player2 = $Players/P2
@onready var fade = $DynamicCamera/Fades

func _ready() -> void:
	# Register both players to the camera on startup
	camera.add_target(player1)
	camera.add_target(player2)
	fade.play("Fade Out")
