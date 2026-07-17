class_name Snake
extends Node2D

const DIRECTIONS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

var body_cells: Array[Vector2i] = []
var current_direction := Vector2i.RIGHT
var buffered_direction := Vector2i.RIGHT
var pending_growth: int = 0
var cell_size: int = 16

var head_color := Color("1f6f3d")
var body_color := Color("2ea95b")
var outline_color := Color("0d331c")


func configure(new_cell_size: int) -> void:
	cell_size = new_cell_size
	queue_redraw()


func start(start_cell: Vector2i, start_length: int = 3, start_direction: Vector2i = Vector2i.RIGHT) -> void:
	body_cells.clear()
	current_direction = start_direction
	buffered_direction = start_direction
	pending_growth = 0

	for i in range(start_length):
		body_cells.append(start_cell - start_direction * i)

	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	for action in DIRECTIONS:
		if event.is_action_pressed(action):
			var requested_direction: Vector2i = DIRECTIONS[action]
			if requested_direction == -current_direction:
				return
			buffered_direction = requested_direction
			return


func step(board: Board, fruit_cell: Vector2i) -> Dictionary:
	if body_cells.is_empty():
		return {"status": "dead", "reason": "empty_snake"}

	if buffered_direction != -current_direction:
		current_direction = buffered_direction

	var next_head := body_cells[0] + current_direction
	if not board.is_cell_in_bounds(next_head):
		return {"status": "dead", "reason": "boundary"}

	if board.is_cell_blocked(next_head):
		return {"status": "dead", "reason": "obstacle"}

	var ate_fruit := next_head == fruit_cell
	var growth_this_tick := pending_growth
	if ate_fruit:
		growth_this_tick += 1

	var body_check_count := body_cells.size() if growth_this_tick > 0 else body_cells.size() - 1
	for i in range(body_check_count):
		if next_head == body_cells[i]:
			return {"status": "dead", "reason": "self"}

	body_cells.push_front(next_head)

	if growth_this_tick > 0:
		pending_growth = growth_this_tick - 1
	else:
		body_cells.pop_back()

	queue_redraw()

	if ate_fruit:
		return {"status": "ate_fruit", "head": next_head}

	return {"status": "moved", "head": next_head}


func get_occupied_cells() -> Array[Vector2i]:
	return body_cells.duplicate()


func get_head_cell() -> Vector2i:
	return body_cells[0] if not body_cells.is_empty() else Vector2i.ZERO


func _draw() -> void:
	var inset := 1.0
	for i in range(body_cells.size() - 1, -1, -1):
		var cell := body_cells[i]
		var rect := Rect2(
			Vector2(cell.x * cell_size + inset, cell.y * cell_size + inset),
			Vector2(cell_size - inset * 2.0, cell_size - inset * 2.0)
		)
		draw_rect(rect, body_color if i > 0 else head_color)
		draw_rect(rect, outline_color, false, 1.0)
