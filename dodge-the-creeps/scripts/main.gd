extends Node

@export var mob_scene: PackedScene

var score
@export var lives: int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#new_game()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func game_over() -> void:
	print("game over")
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$GameOverSound.play()
	print(score)

func new_game():
	get_tree().call_group("mobs", "queue_free")
	
	score = 0
	
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	for node in $HUD/HeartContainer.get_children():
		node.show()
	
	lives = 3
	$Music.play()

func _on_mob_timer_timeout() -> void:
	var mob = mob_scene.instantiate()
	
	# Choose a random location on Path2D.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	# Set the mob's position to the random location.
	mob.position = get_spawn_position_outside_screen()

	# Set the mob's direction perpendicular to the path direction.
	var direction = mob_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Choose the velocity for the mob.
	var velocity = Vector2(randf_range(150.0, 250.0), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)


func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	
func get_spawn_position_outside_screen() -> Vector2:	
	# Get the viewport rectangle in local screen coordinates.
	var screen_rect := get_viewport().get_visible_rect()

	# Add padding so mobs spawn slightly outside the screen, not right on the edge.
	var padding := 40.0

	# Try several random points on the path until one is outside the screen.
	for i in range(10):
		var mob_spawn_location = $MobPath/MobSpawnLocation
		mob_spawn_location.progress_ratio = randf()

		var spawn_position: Vector2 = mob_spawn_location.position

		# Create a smaller "unsafe" screen area.
		# If the spawn point is inside this rect, reject it.
		var unsafe_rect = screen_rect

		if not unsafe_rect.has_point(spawn_position):
			return spawn_position
	# Fallback: return whatever point we got if all attempts failed.
	return $MobPath/MobSpawnLocation.position


func _on_hud_start_game() -> void:
	new_game()


func _on_player_hit() -> void:
	print("hit")
	lives -= 1
	print(lives)
	if lives < 1:
		$Player/CollisionShape2D.set_deferred("disabled", true)
		game_over()
	
	var hearts: Array = $HUD/HeartContainer.get_children()
	print(hearts)
	if not hearts.is_empty():
		hearts.get(lives).hide()
	print(hearts)
	
	
	
