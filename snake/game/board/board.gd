class_name Board
extends Node2D

enum Biome {
	GRASS,
	FOREST,
	DESERT,
	ICE,
}

# Board width and height are in cells.
@export var board_width: int = 25
@export var board_height: int = 25

# The board owns gameplay cell size. It is derived from the Ground TileSet so
# object placement always matches the rendered grid.
var cell_size: int = 16

@export var ground_source_id: int = 0
@export var ground_alternative_tile: int = 0
@export var ground_variants: Array[Vector2i] = [
	Vector2i(0, 7),
	Vector2i(1, 7),
	Vector2i(2, 7),
	Vector2i(3, 7),
	Vector2i(0, 8),
	Vector2i(1, 8),
	Vector2i(2, 8),
	Vector2i(3, 8),
]
@export var obstacle_source_id: int = 0
@export var obstacle_alternative_tile: int = 0
@export var current_biome: Biome = Biome.GRASS
@export_range(0.0, 1.0, 0.01) var grass_obstacle_fill_ratio: float = 0.05
@export_range(0.0, 1.0, 0.01) var forest_obstacle_fill_ratio: float = 0.14
@export_range(0.0, 1.0, 0.01) var desert_obstacle_fill_ratio: float = 0.06
@export_range(0.0, 1.0, 0.01) var ice_obstacle_fill_ratio: float = 0.08
@export var snake_spawn_cell := Vector2i(12, 12)
@export var snake_spawn_clear_radius: int = 2
@export var reserve_fruit_cell: bool = true
@export var fruit_cell := Vector2i(10, 10)

@onready var ground: TileMapLayer = $Ground
# Obstacle scene instances live under this node.
@onready var obstacles_root: Node2D = $Obstacles
@onready var obstacle_templates_root: Node2D = $ObstacleTemplates

var board_size := Vector2i(board_width, board_height)
var rng := RandomNumberGenerator.new()

# Fast lookup table for gameplay checks like snake collision.
var obstacle_cells: Dictionary[Vector2i, bool] = {}
var pickup_cells: Dictionary[Vector2i, bool] = {}

func start_new_run() -> void:
	board_size = Vector2i(board_width, board_height)
	_sync_cell_size_from_tileset()
	rng.randomize()
	spawn_random_obstacles()
	draw_board()


func draw_board() -> void:
	draw_ground()
	# Obstacles own their own visuals, so the board only rebuilds blocked cells.
	rebuild_obstacle_cells()


func draw_ground() -> void:
	ground.clear()

	if ground_variants.is_empty():
		return

	for x in range(board_width):
		for y in range(board_height):
			var atlas_coords := ground_variants[rng.randi_range(0, ground_variants.size() - 1)]
			ground.set_cell(
				Vector2i(x, y),
				ground_source_id,
				atlas_coords,
				ground_alternative_tile
			)


func configure_obstacle(obstacle: Obstacle2D) -> void:
	# Every obstacle reuses the board TileSet so all atlas coords come from one sheet.
	obstacle.configure(
		ground.tile_set,
		cell_size,
		obstacle_source_id,
		obstacle_alternative_tile
	)


func spawn_random_obstacles() -> void:
	for child in obstacles_root.get_children():
		child.free()

	var templates: Array[Obstacle2D] = []
	for child in obstacle_templates_root.get_children():
		if child is Obstacle2D:
			templates.append(child)

	if templates.is_empty():
		return

	var occupied := get_reserved_cells()
	var reserved_count := occupied.size()
	var target_obstacle_cells := int(round(board_width * board_height * get_current_obstacle_fill_ratio()))
	var attempts := 0
	var max_attempts : Variant = max(target_obstacle_cells, 1) * 20

	while occupied.size() - reserved_count < target_obstacle_cells and attempts < max_attempts:
		attempts += 1

		var template := templates[rng.randi_range(0, templates.size() - 1)]
		var origin := Vector2i(
			rng.randi_range(0, board_width - 1),
			rng.randi_range(0, board_height - 1)
		)

		if not can_place_obstacle(template, origin, occupied):
			continue

		var obstacle := template.duplicate() as Obstacle2D
		obstacles_root.add_child(obstacle)
		obstacle.move_to_cell(origin)
		configure_obstacle(obstacle)

		for cell in obstacle.get_occupied_cells():
			occupied[cell] = true


func can_place_obstacle(template: Obstacle2D, origin: Vector2i, occupied: Dictionary[Vector2i, bool]) -> bool:
	for local_cell in template.footprint:
		var board_cell := origin + local_cell

		if not is_cell_in_bounds(board_cell):
			return false

		if occupied.has(board_cell):
			return false

	return true


func get_reserved_cells() -> Dictionary[Vector2i, bool]:
	var reserved: Dictionary[Vector2i, bool] = {}

	# Keep a clear area around the snake spawn so the opening state is playable.
	for x in range(
		snake_spawn_cell.x - snake_spawn_clear_radius,
		snake_spawn_cell.x + snake_spawn_clear_radius + 1
	):
		for y in range(
			snake_spawn_cell.y - snake_spawn_clear_radius,
			snake_spawn_cell.y + snake_spawn_clear_radius + 1
		):
			var reserved_cell := Vector2i(x, y)
			if not is_cell_in_bounds(reserved_cell):
				continue

			reserved[reserved_cell] = true

	if reserve_fruit_cell and is_cell_in_bounds(fruit_cell):
		reserved[fruit_cell] = true

	return reserved


func rebuild_obstacle_cells() -> void:
	obstacle_cells.clear()

	for child in obstacles_root.get_children():
		if child is Obstacle2D:
			# Convert each obstacle's local footprint into board-space occupied cells.
			for cell in child.get_occupied_cells():
				obstacle_cells[cell] = true


func shift_obstacle(obstacle: Obstacle2D, delta: Vector2i) -> void:
	# When an obstacle moves, rebuild the lookup so gameplay stays in sync.
	obstacle.shift_by(delta)
	rebuild_obstacle_cells()


func get_current_obstacle_fill_ratio() -> float:
	match current_biome:
		Biome.FOREST:
			return forest_obstacle_fill_ratio
		Biome.DESERT:
			return desert_obstacle_fill_ratio
		Biome.ICE:
			return ice_obstacle_fill_ratio
		_:
			return grass_obstacle_fill_ratio


func set_biome(new_biome: Biome) -> void:
	current_biome = new_biome
	start_new_run()


func set_fruit_cell(new_fruit_cell: Vector2i) -> void:
	fruit_cell = new_fruit_cell


func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < board_width and cell.y >= 0 and cell.y < board_height


func is_cell_blocked(cell: Vector2i) -> bool:
	return obstacle_cells.has(cell)


func get_pixel_size() -> Vector2:
	return Vector2(board_width * cell_size, board_height * cell_size)


func cell_to_local(cell: Vector2i) -> Vector2:
	return Vector2(
		(cell.x + 0.5) * cell_size,
		(cell.y + 0.5) * cell_size
	)


func get_random_free_cell(excluded_cells: Array[Vector2i] = []) -> Vector2i:
	var excluded_lookup: Dictionary[Vector2i, bool] = {}
	for cell in excluded_cells:
		excluded_lookup[cell] = true

	var free_cells: Array[Vector2i] = []
	for x in range(board_width):
		for y in range(board_height):
			var candidate := Vector2i(x, y)
			if obstacle_cells.has(candidate):
				continue
			if excluded_lookup.has(candidate):
				continue
			free_cells.append(candidate)

	if free_cells.is_empty():
		return Vector2i(-1, -1)

	return free_cells[rng.randi_range(0, free_cells.size() - 1)]


func _sync_cell_size_from_tileset() -> void:
	if ground.tile_set != null:
		cell_size = ground.tile_set.tile_size.x
