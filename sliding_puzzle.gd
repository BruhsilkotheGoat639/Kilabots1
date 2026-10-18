extends Control

const GRID_SIZE = 3
const TILE_SIZE = 120

var empty_cell := Vector2(2, 2)
var board := {} 

var is_sliding := false 
var is_active := false # Locks the puzzle from being played

func _ready() -> void:
	var value = 1
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if x == 2 and y == 2:
				board[Vector2(x, y)] = null
				continue
			
			var btn = Button.new()
			btn.text = str(value)
			btn.size = Vector2(TILE_SIZE, TILE_SIZE)
			btn.position = Vector2(x, y) * TILE_SIZE
			btn.focus_mode = Control.FOCUS_NONE 
			
			btn.pressed.connect(_on_tile_pressed.bind(btn))
			
			add_child(btn)
			board[Vector2(x, y)] = btn
			value += 1
			
	# Notice shuffle_board() has been removed from here!
	#start_puzzle()

# Call this function from your main game script when you want the minigame to begin
func start_puzzle() -> void:
	shuffle_board()
	is_active = true

func _input(event: InputEvent) -> void:
	# Block all keyboard inputs if the puzzle hasn't started yet
	if not is_active or is_sliding:
		return
		
	var target_tile := Vector2(-1, -1)
	
	if event.is_action_pressed("P2Jump"): 
		target_tile = empty_cell + Vector2.DOWN
	elif event.is_action_pressed("P2Down"): 
		target_tile = empty_cell + Vector2.UP
	elif event.is_action_pressed("P2Left"): 
		target_tile = empty_cell + Vector2.RIGHT
	elif event.is_action_pressed("P2Right"): 
		target_tile = empty_cell + Vector2.LEFT
		
	if target_tile != Vector2(-1, -1):
		if target_tile.x >= 0 and target_tile.x < GRID_SIZE and target_tile.y >= 0 and target_tile.y < GRID_SIZE:
			slide_tile(target_tile, empty_cell)

func _on_tile_pressed(clicked_btn: Button) -> void:
	# Block all mouse clicks if the puzzle hasn't started yet
	if not is_active or is_sliding:
		return
		
	var clicked_pos := Vector2.ZERO
	for pos in board:
		if board[pos] == clicked_btn:
			clicked_pos = pos
			break
			
	if clicked_pos.distance_to(empty_cell) == 1.0:
		slide_tile(clicked_pos, empty_cell)

func slide_tile(start_pos: Vector2, target_pos: Vector2) -> void:
	is_sliding = true
	var btn = board[start_pos]
	
	board[target_pos] = btn
	board[start_pos] = null
	empty_cell = start_pos
	
	var tween = create_tween()
	tween.tween_property(btn, "position", target_pos * TILE_SIZE, 0.15)
	
	tween.finished.connect(func():
		is_sliding = false
		check_win()
	)

func shuffle_board() -> void:
	for i in range(100):
		var neighbors = [
			empty_cell + Vector2.UP,
			empty_cell + Vector2.DOWN,
			empty_cell + Vector2.LEFT,
			empty_cell + Vector2.RIGHT
		]
		
		var valid_neighbors = []
		for n in neighbors:
			if n.x >= 0 and n.x < GRID_SIZE and n.y >= 0 and n.y < GRID_SIZE:
				valid_neighbors.append(n)
				
		var random_move = valid_neighbors.pick_random()
		
		var btn = board[random_move]
		board[empty_cell] = btn
		board[random_move] = null
		btn.position = empty_cell * TILE_SIZE
		empty_cell = random_move

func check_win() -> void:
	var expected_val = 1
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if x == 2 and y == 2: 
				continue
			
			var btn = board[Vector2(x, y)]
			if btn == null or btn.text != str(expected_val):
				return
			
			expected_val += 1
	
	# Lock the puzzle again once it is solved
	is_active = false
	print("Puzzle Solved!")
