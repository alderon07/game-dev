extends Area2D

signal pickup
signal hurt

@export var speed: int = 350
var velocity = Vector2.ZERO
var screensize = Vector2(480, 720)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func start():
	set_process(true)
	position = screensize / 2
	sprite.animation = "idle"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	position += velocity * speed * delta
	position.x = clamp(position.x, 0, screensize.x)
	position.y = clamp(position.y, 0, screensize.y)
	
	if velocity.length() > 0:
		sprite.animation = "run"
	else:
		sprite.animation = "idle"
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func die():
	sprite.animation = "hurt"
	set_process(false)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("coins"):
		area.pickup()
		pickup.emit()
	
	if area.is_in_group("obstacles"):
		hurt.emit()
		die()
