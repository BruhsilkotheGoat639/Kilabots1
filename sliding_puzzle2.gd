extends Node2D

@export var puzzle_image: Texture2D
const GRID_SIZE = 3

var tile_size: Vector2
var empty_cell: Vector2i = Vector2i(GRID_SIZE - 1, GRID_SIZE - 1)
var grid: Dictionary = {} 

func _ready():
	if not puzzle_image:
		push_error("Please assign an image to the PuzzleBoard in the Inspector!")
		return

	# Calculate how big each tile should be based on the image size
	tile_size = puzzle_image.get_size() / float(GRID_SIZE)
	create_tiles()
	shuffle_tiles()

func create_tiles():
	for x in range(GRID_SIZE):
		for y in range(GRID_SIZE):
			# Leave the bottom-right corner empty
			if x == GRID_SIZE - 1 and y == GRID_SIZE - 1:
				continue

			var sprite = Sprite2D.new()
			sprite.texture = puzzle_image
			sprite.region_enabled = true
			# Slice out a specific square of the image for this tile
			sprite.region_rect = Rect2(x * tile_size.x, y * tile_size.y, tile_size.x, tile_size.y)
			sprite.position = Vector2(x, y) * tile_size + (tile_size / 2.0)
			add_child(sprite)

			# Store the sprite in our dictionary using its grid coordinates
			grid[Vector2i(x, y)] = sprite

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_local_mouse_position()

		# Prevent clicks outside the puzzle boundaries
		if click_pos.x < 0 or click_pos.y < 0 or click_pos.x > puzzle_image.get_width() or click_pos.y > puzzle_image.get_height():
			return

		# Convert mouse coordinates into a grid coordinate (e.g., 0,0 or 2,1)
		var grid_pos = Vector2i(int(click_pos.x / tile_size.x), int(click_pos.y / tile_size.y))

		# If we clicked a valid tile and it's next to the empty space, move it
		if grid.has(grid_pos) and is_adjacent(grid_pos, empty_cell):
			move_tile(grid_pos)

func is_adjacent(cell1: Vector2i, cell2: Vector2i) -> bool:
	# A mathematical trick to check if two grid cells are exactly 1 step apart
	return abs(cell1.x - cell2.x) + abs(cell1.y - cell2.y) == 1

func move_tile(cell: Vector2i, animate: bool = true):
	var tile = grid[cell]
	
	# Swap the dictionary data
	grid.erase(cell)
	grid[empty_cell] = tile

	var target_pos = Vector2(empty_cell) * tile_size + (tile_size / 2.0)

	# Visually slide the tile
	if animate:
		var tween = create_tween()
		tween.tween_property(tile, "position", target_pos, 0.15).set_trans(Tween.TRANS_SINE)
		tween.finished.connect(check_win)
	else:
		tile.position = target_pos

	# Update the empty cell's position
	empty_cell = cell

func shuffle_tiles():
	# We shuffle by simulating random legal moves to ensure the puzzle is mathematically solvable
	for i in range(100):
		var neighbors = []
		var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		for dir in dirs:
			var neighbor = empty_cell + dir
			if neighbor.x >= 0 and neighbor.x < GRID_SIZE and neighbor.y >= 0 and neighbor.y < GRID_SIZE:
				neighbors.append(neighbor)

		var random_neighbor = neighbors[randi() % neighbors.size()]
		# Pass false so the shuffling happens instantly before the screen renders
		move_tile(random_neighbor, false)

func check_win():
	# If the empty space isn't in the bottom right, they haven't won yet
	if empty_cell != Vector2i(GRID_SIZE - 1, GRID_SIZE - 1):
		return

	# Check if every tile is back in its original position
	for cell in grid:
		var tile = grid[cell]
		var original_x = int(tile.region_rect.position.x / tile_size.x)
		var original_y = int(tile.region_rect.position.y / tile_size.y)
		
		if original_x != cell.x or original_y != cell.y:
			return 
			
	print("Puzzle Solved!")
