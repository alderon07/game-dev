class_name Fruit
extends Node2D

var cell := Vector2i.ZERO


func set_cell(new_cell: Vector2i, board: Board) -> void:
	cell = new_cell
	position = board.cell_to_local(cell)


func get_cell() -> Vector2i:
	return cell
