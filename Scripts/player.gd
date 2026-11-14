extends CharacterBody2D

var speed = 600
const BULLET = preload("res://Scenes/ball.tscn")
const UPGRADE_MENU = preload("res://Scripts/upgrade_menu.gd")
var max_health = 3
var health = 3
var invuln = 0.0

# stuff upgrades change
var shoot_cooldown = 0.5
var ball_bounces = 3
var ball_speed = 800.0

@onready var shoot_timer: Timer = $Timer

func _ready():
	shoot_timer.one_shot = true

func _physics_process(delta):
	var dir = Vector2.ZERO
	if Input.is_action_pressed("right"): dir.x += 1
	if Input.is_action_pressed("left"): dir.x -= 1
	if Input.is_action_pressed("down"): dir.y += 1
	if Input.is_action_pressed("up"): dir.y -= 1

	velocity = dir.normalized() * speed
	move_and_slide()

	if invuln > 0:
		invuln -= delta

func take_damage():
	if invuln > 0:
		return
	health -= 1
	invuln = 0.5
	if health <= 0:
		dead()


func dead():
	# kill everything, pause, show upgrades
	get_tree().call_group("enemies", "die")
	get_tree().call_group("spawner", "restart")
	get_tree().paused = true
	var menu = UPGRADE_MENU.new()
	menu.upgrade_chosen.connect(_apply_upgrade)
	get_tree().current_scene.add_child(menu)


func _apply_upgrade(id):
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
	invuln = 1.0
	get_tree().paused = false

func spawn_bullet(pos, direction):
	var b = BULLET.instantiate()
	b.add_collision_exception_with(self)
	get_tree().current_scene.add_child(b)
	b.global_position = pos
	b.direction = direction
	b.max_bounces = ball_bounces
	b.speed = ball_speed

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if shoot_timer.is_stopped():
			var d = (get_global_mouse_position() - global_position).normalized()
			spawn_bullet(global_position, d)
			shoot_timer.start(shoot_cooldown)
