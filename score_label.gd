extends CanvasLayer

@onready var label: Label = $Label

func _ready() -> void:
	pass
	

func _process(_delta: float) -> void:
	if ScoreManager:
		label.text = "Score: " + str(ScoreManager.score)
