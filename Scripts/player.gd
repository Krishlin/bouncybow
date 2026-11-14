extends CharacterBody2D

var speed = 600
const BULLET = preload("res://Scenes/ball.tscn")
const UPGRADE_MENU = preload("res://Scripts/upgrade_menu.gd")
var max_health = 3
var health = 3
var invulnerable_time = 0.0

# Upgradeable stats
var shoot_cooldown = 0.5
var ball_bounces = 3
var ball_speed = 800.0

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

	if invulnerable_time > 0:
		invulnerable_time -= _delta

func take_damage() -> void:
	
	if invulnerable_time > 0:
		return
	health -= 1
	invulnerable_time = 0.5
	if health <= 0:
		_on_out_of_health()


func _on_out_of_health() -> void:
	# Kill every enemy, pause the game and let the player pick an upgrade.
	get_tree().call_group("enemies", "die")
	get_tree().paused = true
	var menu = UPGRADE_MENU.new()
	menu.upgrade_chosen.connect(_apply_upgrade)
	get_tree().current_scene.add_child(menu)


func _apply_upgrade(id: String) -> void:
	match id:
		"max_health":
			max_health += 1
		"speed":
			speed *= 1.15
		"fire_rate":
			shoot_cooldown *= 0.8
		"bounces":
			ball_bounces += 1
		"ball_speed":
			ball_speed *= 1.2
	health = max_health
	invulnerable_time = 1.0
	get_tree().paused = false

func spawn_bullet(pos: Vector2, direction: Vector2) -> void:
	var instance = BULLET.instantiate()
	instance.add_collision_exception_with(self)
	get_tree().current_scene.add_child(instance)
	instance.global_position = pos
	instance.direction = direction
	instance.max_bounces = ball_bounces
	instance.speed = ball_speed

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

		if shoot_timer.is_stopped():
			var mouse: Vector2 = get_global_mouse_position()
			var dir: Vector2 = (mouse - global_position).normalized()
			spawn_bullet(global_position, dir)


			shoot_timer.start(shoot_cooldown)
