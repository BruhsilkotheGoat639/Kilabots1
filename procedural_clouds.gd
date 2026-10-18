extends Sprite2D # (Change to TextureRect if you used a TextureRect)

@export var wind_speed := 100.0

func _process(delta: float) -> void:
	# Check if the texture and noise are properly assigned
	if texture is NoiseTexture2D and texture.noise is FastNoiseLite:
		var noise = texture.noise as FastNoiseLite
		
		# Move the internal noise coordinates on the X axis to simulate wind
		# (Note: FastNoiseLite uses a Vector3 for its offset)
		noise.offset.x += wind_speed * delta
