extends TileMap


@export var search_rect = Rect2i(-9, -6, 23, 20)

enum Direction {
	TOP,
	LEFT,
	TOPRIGHT,
	TOPLEFT,
	BOTTOM,
	RIGHT,
	BOTTOMLEFT,
	BOTTOMRIGHT,
}

# Stable diffusion?
# Probability based on how often a block is placed

# Funky array to store every occurance of a tile being next to another. The more a tile is next to another, the more likely they are to be next to each other again
var probabilities = []
# Save all possible tile coordinates in an Array for randomization later
var positions : Array[Vector2i] = []
# Save all possible atlas coordinates for later use
var all_atlas_coordinates := {}
var all_atlas_coordinates_array := []
var atlas_coords_count = 0

var collapse_radius = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	# Gather some basic info needed to construct the probability array
	for x in range(search_rect.position.x, search_rect.position.x + search_rect.size.x):
		for y in range(search_rect.position.y , search_rect.position.y + search_rect.size.y):
			var tilemap_coords = Vector2i(x, y)
			var atlas_coords = get_cell_atlas_coords(0, tilemap_coords)
			
			# Add atlas coordinate to the hash
			if not all_atlas_coordinates.has((atlas_coords)) and atlas_coords != Vector2i(-1, -1):
				all_atlas_coordinates[atlas_coords] = all_atlas_coordinates.keys().size()
				all_atlas_coordinates_array.append(atlas_coords)
			
			# Add the position to the list
			positions.append(tilemap_coords)
	
	atlas_coords_count = all_atlas_coordinates.keys().size()
	
	probabilities = calculate_probabilities(positions, all_atlas_coordinates, search_rect)
	
	clear()


func calculate_probabilities(positions: Array[Vector2i], all_atlas_coordinates: Dictionary, search_rect: Rect2i) -> Array[int]:
	var atlas_coords_count = all_atlas_coordinates.keys().size()
	
	var probabilities : Array[int] = []
	probabilities.resize((atlas_coords_count * Direction.keys().size()) * atlas_coords_count)
	probabilities.fill(0)
	
	var offset = search_rect.position + Vector2i(1, 1)
	for x in search_rect.size.x - 2:
		for y in search_rect.size.y - 2:
			var coordinates = Vector2i(x, y) + offset
			var atlas_coordinates = get_cell_atlas_coords(0, coordinates)
			
			if atlas_coordinates == Vector2i(-1, -1):
				continue
			
			var type = all_atlas_coordinates[atlas_coordinates]
			
			for direction in Direction.values():
				var neighbor_atlas_coords = neighbor_atlas_coordinates(coordinates, direction)
				
				if neighbor_atlas_coords != Vector2i(-1, -1):
					var neighbor_type = all_atlas_coordinates[neighbor_atlas_coords]
					# Increase probability
					var index = probability_index(type, direction, neighbor_type)
					probabilities[index] += 1
					index = probability_index(neighbor_type, (direction + 4) % 8, type)
					probabilities[index] += 1
	
	return probabilities


func collapse(coordinate: Vector2i) -> void:
	if get_cell_atlas_coords(0, coordinate) != Vector2i(-1, -1):
		return
	
	var probability_per_type : Array[int] = []
	probability_per_type.resize(atlas_coords_count)
	probability_per_type.fill(1)
	
	for direction in Direction.values():
		var neighbor_atlas_coords = neighbor_atlas_coordinates(coordinate, direction)
		
		if neighbor_atlas_coords != Vector2i(-1, -1):
			var neighbor_type = all_atlas_coordinates[neighbor_atlas_coords]
			
			for type in atlas_coords_count:
				var probability = get_probability(type, direction, neighbor_type)
				probability_per_type[type] *= probability
	
	var type = pick_cell_type(probability_per_type)
	
	if type == null:
		type = randi_range(0, all_atlas_coordinates_array.size() - 1)
		
		print("Shit")
		
		# My final message
		for x in range(-1, 2):
			for y in range(-1, 2):
				set_cell(0, coordinate + Vector2i(x, y), 0, Vector2i(-1, -1))
	
	set_cell(0, coordinate, 0, all_atlas_coordinates_array[type])


func pick_cell_type(probabilities: Array[int]):
	# Cum sum, hehe
	var cum_sum = 0.0
	var cum_prob = []
	for probability in probabilities:
		cum_sum += pow(probability, 0.25)
		cum_prob.append(cum_sum)
	
	var string = "["
	for i in cum_prob.size():
		# Normalize
		cum_prob[i] /= cum_sum
		var float_str = str(cum_prob[i])
	
	var random = randf()
	for i in cum_prob.size():
		if random <= cum_prob[i]:
			return i
	
	# I can't solve it ):
	return null


func neighbor_atlas_coordinates(coordinate: Vector2i, direction: Direction):
	var delta = Vector2i.ZERO
	
	match direction:
		Direction.LEFT: delta = Vector2i(-1, 0)
		Direction.RIGHT: delta = Vector2i(1, 0)
		Direction.TOP: delta = Vector2i(0, -1)
		Direction.BOTTOM: delta = Vector2i(0, 1)
		Direction.TOPRIGHT: delta = Vector2i(1, -1)
		Direction.TOPLEFT: delta = Vector2i(-1, -1)
		Direction.BOTTOMLEFT: delta = Vector2i(-1, 1)
		Direction.BOTTOMRIGHT: delta = Vector2i(1, 1)
	
	var neighbor_atlas_coordinates = get_cell_atlas_coords(0, coordinate + delta)
	
	return neighbor_atlas_coordinates


func get_probability(type: int, direction: Direction, neighbor_type: int) -> int:
	var index = probability_index(type, direction, neighbor_type)
	return probabilities[index] 


func probability_index(type: int, direction: Direction, neighbor_type: int) -> int:
	return type * atlas_coords_count * Direction.keys().size() + direction * atlas_coords_count + neighbor_type


func _process(event):
	# Go out radially and collapse the wave function
	for radius in range(1, 20):
		for x in range(- radius, radius - 1):
			collapse(local_to_map(get_node("/root/Main/CharacterBody2D").position) + Vector2i(x, -radius))
		for y in range(- radius, radius - 1):
			collapse(local_to_map(get_node("/root/Main/CharacterBody2D").position) + Vector2i(radius - 1, y))
		for x in range(1 - radius, radius):
			collapse(local_to_map(get_node("/root/Main/CharacterBody2D").position) + Vector2i(x, radius))
		for y in range(1 - radius, radius):
			collapse(local_to_map(get_node("/root/Main/CharacterBody2D").position) + Vector2i(- radius, y))
	#for x in range(-20, 20):
		#for y in range(-20, 20):
			#collapse(local_to_map(get_node("/root/Main/CharacterBody2D").position) + Vector2i(x, y))
	if Input.is_action_pressed("collapse"):
		var mouse_pos = get_local_mouse_position()
		var tile_pos = local_to_map(mouse_pos)
		collapse_radius = max(collapse_radius, 1)
		for x in range(1 - collapse_radius, collapse_radius):
			for y in range(1 - collapse_radius, collapse_radius):
				set_cell(0, tile_pos + Vector2i(x, y), 0, Vector2i(-1, -1))
	
	if Input.is_action_just_pressed("collapse_radius_increase"):
		collapse_radius += 1
	if Input.is_action_just_pressed("collapse_radius_decrease"):
		collapse_radius -= 1
