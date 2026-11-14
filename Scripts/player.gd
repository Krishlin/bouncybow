extends CharacterBody2D

var speed = 600
const BULLET = preload("res://Scenes/ball.tscn")


@onready var shoot_timer: Timer = $Timer

func _ready() -> void:
	shoot_timer.one_shot = true

func _physics_process(_delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("right"):
		direction.x += 1
	if Input.is_action_pressed("left"):
		direction.x -= 1
	if Input.is_action_pressed("down"):
		direction.y += 1
	if Input.is_action_pressed("up"):
		direction.y -= 1

	velocity = direction.normalized() * speed
	move_and_slide()

func spawn_bullet(pos: Vector2, direction: Vector2) -> void:
	var instance = BULLET.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = pos
	instance.direction = direction

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		if shoot_timer.is_stopped():
			var mouse: Vector2 = get_global_mouse_position()
			var dir: Vector2 = (mouse - global_position).normalized()
			spawn_bullet(global_position, dir)


			shoot_timer.start(0.5)
