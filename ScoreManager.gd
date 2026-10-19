extends Node

var score: int = 0

func add_score(amount: int) -> void:
	score += amount
	print("Score: ", score)

func subtract_score(amount: int) -> void:
	score = max(0, score - amount) # Prevents score from dropping below 0
	print("Score: ", score)

func reset_score() -> void:
	score = 0
