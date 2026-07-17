extends Node

const BOARD_SCENE := preload("res://game/board/Board.tscn")
const SNAKE_SCENE := preload("res://game/snake/Snake.tscn")
const FRUIT_SCENE := preload("res://game/fruit/Fruit.tscn")
const SAVE_PATH := "user://save.cfg"
const FRUIT_SCORE := 10

@export var move_interval: float = 0.18
@export var snake_start_length: int = 3

@onready var run_root: Node = $Run
@onready var world_root: Node2D = $World
@onready var score_label: Label = $Interface/HUD/Panel/VBox/ScoreLabel
@onready var best_score_label: Label = $Interface/HUD/Panel/VBox/BestScoreLabel
@onready var start_screen: Control = $Interface/StartScreen
@onready var start_button: Button = $Interface/StartScreen/CenterContainer/Panel/VBox/StartButton
@onready var game_over_screen: Control = $Interface/GameOverScreen
@onready var game_over_reason_label: Label = $Interface/GameOverScreen/CenterContainer/Panel/VBox/ReasonLabel
@onready var game_over_score_label: Label = $Interface/GameOverScreen/CenterContainer/Panel/VBox/ScoreLabel
@onready var restart_button: Button = $Interface/GameOverScreen/CenterContainer/Panel/VBox/RestartButton

var board: Board
var snake: Snake
var fruit: Fruit
var move_timer: Timer
var game_over: bool = false
var score: int = 0
var best_score: int = 0


func _ready() -> void:
	board = BOARD_SCENE.instantiate() as Board
	world_root.add_child(board)

	snake = SNAKE_SCENE.instantiate() as Snake
	board.add_child(snake)

	fruit = FRUIT_SCENE.instantiate() as Fruit
	board.add_child(fruit)

	move_timer = Timer.new()
	move_timer.wait_time = move_interval
	move_timer.one_shot = false
	move_timer.autostart = false
	move_timer.timeout.connect(_on_move_timer_timeout)
	run_root.add_child(move_timer)

	start_button.pressed.connect(_on_start_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

	_load_best_score()
	_update_score_labels()
	board.start_new_run()
	_center_board()
	snake.configure(board.cell_size)
	fruit.hide()
	_show_start_screen()


func _unhandled_input(event: InputEvent) -> void:
	if not game_over:
		return

	if event.is_action_pressed("ui_accept"):
		start_new_run()
		return

	if InputMap.has_action("confirm") and event.is_action_pressed("confirm"):
		start_new_run()
		return

	if InputMap.has_action("quick_restart") and event.is_action_pressed("quick_restart"):
		start_new_run()


func start_new_run() -> void:
	game_over = false
	score = 0
	board.start_new_run()
	_center_board()

	snake.configure(board.cell_size)
	snake.start(board.snake_spawn_cell, snake_start_length)

	_update_score_labels()
	start_screen.hide()
	game_over_screen.hide()
	_spawn_fruit()
	move_timer.start()


func _spawn_fruit() -> void:
	var next_fruit_cell := board.get_random_free_cell(snake.get_occupied_cells())
	if next_fruit_cell == Vector2i(-1, -1):
		_end_run("no_free_fruit_cells")
		return

	board.set_fruit_cell(next_fruit_cell)
	fruit.show()
	fruit.set_cell(next_fruit_cell, board)


func _on_move_timer_timeout() -> void:
	if game_over:
		return

	var move_result := snake.step(board, fruit.get_cell())
	match move_result.get("status", "dead"):
		"ate_fruit":
			_add_score(FRUIT_SCORE)
			_spawn_fruit()
		"dead":
			_end_run(str(move_result.get("reason", "unknown")))


func _end_run(reason: String) -> void:
	game_over = true
	move_timer.stop()
	if score > best_score:
		best_score = score
		_save_best_score()
	_update_score_labels()
	game_over_reason_label.text = _format_game_over_reason(reason)
	game_over_score_label.text = "Score: %d" % score
	game_over_screen.show()
	restart_button.grab_focus()


func _center_board() -> void:
	board.position = (get_viewport().get_visible_rect().size - board.get_pixel_size()) * 0.5


func _show_start_screen() -> void:
	start_screen.show()
	game_over_screen.hide()
	start_button.grab_focus()


func _format_game_over_reason(reason: String) -> String:
	match reason:
		"boundary":
			return "You hit the wall."
		"obstacle":
			return "You hit an obstacle."
		"self":
			return "You ran into yourself."
		"no_free_fruit_cells":
			return "No space remained for fruit."
		_:
			return "You crashed."


func _on_start_button_pressed() -> void:
	start_new_run()


func _on_restart_button_pressed() -> void:
	start_new_run()


func _add_score(amount: int) -> void:
	score += amount
	_update_score_labels()


func _update_score_labels() -> void:
	score_label.text = "Score: %d" % score
	best_score_label.text = "Best: %d" % best_score


func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		best_score = 0
		return

	best_score = int(config.get_value("score", "best_score", 0))


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("score", "best_score", best_score)
	config.save(SAVE_PATH)
