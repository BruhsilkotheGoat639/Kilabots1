extends CanvasLayer

@onready var score_label: Label = $"High Score" # Matches your node name on the left

func _ready() -> void:
	# Fetch the final score from your global ScoreManager singleton
	if ScoreManager:
		score_label.text = "Score: " + str(ScoreManager.score)
	else:
		score_label.text = "Score: 0"


func _on_home_pressed() -> void:
		get_tree().change_scene_to_file("res://menu.tscn")
	
