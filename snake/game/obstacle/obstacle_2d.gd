class_name Obstacle2D
extends Node2D

@export var origin_cell := Vector2i.ZERO
var cell_size := 16
@export var source_id := 0
@export var alternative_tile := 0

# Each entry is a cell relative to origin_cell that this obstacle blocks.
@export var footprint: Array[Vector2i] = [Vector2i.ZERO]

# Visual tile for the matching footprint index. This lets one obstacle span many cells.
@export var visual_tiles: Array[Vector2i] = [Vector2i.ZERO]

@onready var visual: TileMapLayer = $Visual


func _ready() -> void:
	_sync_position()
	redraw()


func configure(tile_set: TileSet, new_cell_size: int, new_source_id: int, new_alternative_tile: int) -> void:
	# The board injects shared rendering settings so obstacles stay visually consistent.
	visual.tile_set = tile_set
	cell_size = new_cell_size
	source_id = new_source_id
	alternative_tile = new_alternative_tile
	_sync_position()
	redraw()


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for local_cell in footprint:
		# Translate local obstacle cells into board-space cells.
		cells.append(origin_cell + local_cell)

	return cells


func shift_by(delta: Vector2i) -> void:
	origin_cell += delta
	_sync_position()


func move_to_cell(new_origin_cell: Vector2i) -> void:
	origin_cell = new_origin_cell
	_sync_position()


func set_visual_tiles(new_visual_tiles: Array[Vector2i]) -> void:
	visual_tiles = new_visual_tiles
	redraw()


func redraw() -> void:
	visual.clear()

	if visual.tile_set == null or visual_tiles.is_empty():
		return

	for i in range(footprint.size()):
		var local_cell := footprint[i]
		# The visual TileMapLayer is local to the obstacle, so these are local cell coords.
		var atlas_coords := visual_tiles[min(i, visual_tiles.size() - 1)]
		visual.set_cell(local_cell, source_id, atlas_coords, alternative_tile)


func _sync_position() -> void:
	# Move the obstacle scene so its local tile cells line up with board cells.
	position = Vector2(origin_cell * cell_size)
