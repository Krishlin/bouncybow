extends CharacterBody2D

signal died
signal got_hurt

const ARROW = preload("res://Scenes/ball.tscn")
const Upgrades = preload("res://Scripts/upgrades.gd")
const OUTLINE = preload("res://Scripts/outline.gdshader")

# starting stats. upgrades get added on top of these in recalc_stats()
const BASE_SPEED = 480.0
const BASE_MAX_HEALTH = 3
const BASE_SHOOT_COOLDOWN = 0.5
const BASE_BOUNCES = 3
const BASE_ARROW_SPEED = 800.0

const HURT_INVULN = 0.8   # cant be hit again for this long after a hit
const HURT_ANIM = 0.3
const RELEASE_TIME = 0.16 # how long the "arrow just left the bow" frames stay up

var speed = BASE_SPEED
var max_health = BASE_MAX_HEALTH
var health = BASE_MAX_HEALTH
var invuln = 0.0
var is_dead = false

# stuff upgrades change
var shoot_cooldown = BASE_SHOOT_COOLDOWN
var ball_bounces = BASE_BOUNCES
var ball_speed = BASE_ARROW_SPEED
var upgrade_levels = {}  # upgrade id -> how many times its been picked

var firing = false       # shoot button held down
var since_shot = 99.0
var hurt_t = 0.0         # hurt pose
var red_t = 0.0          # red outline
var facing_left = false
var start_pos = Vector2.ZERO
var outline: ShaderMaterial

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready():
	start_pos = position
	outline = ShaderMaterial.new()
	outline.shader = OUTLINE
	sprite.material = outline
	sprite.play("idle")


func _physics_process(delta):
	if is_dead:
		return

	var dir = Input.get_vector("left", "right", "up", "down")
	velocity = dir * speed
	move_and_slide()

	invuln = max(invuln - delta, 0.0)
	hurt_t = max(hurt_t - delta, 0.0)
	red_t = max(red_t - delta, 0.0)
	since_shot += delta

	# the button can get let go while the game is paused and we never hear about it
	if firing and not Input.is_action_pressed("Shoot"):
		firing = false
	if firing and since_shot >= shoot_cooldown:
		shoot()

	update_look(dir)


func _unhandled_input(event):
	if is_dead:
		return
	if event.is_action_pressed("Shoot"):
		firing = true
		if since_shot >= shoot_cooldown:
			shoot()
	elif event.is_action_released("Shoot"):
		firing = false


func shoot():
	var aim = get_global_mouse_position() - global_position
	if aim.length() < 1.0:
		aim = Vector2.LEFT if facing_left else Vector2.RIGHT
	aim = aim.normalized()
	since_shot = 0.0
	Sfx.play("shoot")

	var a = ARROW.instantiate()
	a.direction = aim
	a.max_bounces = ball_bounces
	a.speed = ball_speed
	# starts inside our own body so it can never start out inside a wall
	a.position = global_position + aim * 18
	get_parent().add_child(a)


func update_look(dir):
	if firing or since_shot < RELEASE_TIME:
		facing_left = get_global_mouse_position().x < global_position.x
	elif dir.x != 0:
		facing_left = dir.x < 0
	sprite.flip_h = facing_left

	if hurt_t > 0:
		show_frame("hurt", int((1.0 - hurt_t / HURT_ANIM) * 4.0))
	elif since_shot < RELEASE_TIME:
		# arrow flying off the bow
		show_frame("shoot", 7 if since_shot < RELEASE_TIME / 2 else 8)
	elif firing:
		# pulling the bow back. timed so its fully pulled right when the next arrow is ready
		var pull = (since_shot - RELEASE_TIME) / max(shoot_cooldown - RELEASE_TIME, 0.01)
		show_frame("shoot", 1 + int(clampf(pull, 0.0, 0.99) * 6.0))
	elif dir != Vector2.ZERO:
		play_loop("walk")
	else:
		play_loop("idle")

	# red outline when hurt: solid at first then it blinks
	var red_on = red_t > 0 and (red_t > HURT_INVULN - 0.25 or fmod(red_t, 0.16) > 0.08)
	outline.set_shader_parameter("outline_width", 1.0 if red_on else 0.0)
	# see-through blink for the safe time right after respawning
	var ghost = invuln > 0 and red_t <= 0 and fmod(invuln, 0.2) > 0.1
	sprite.modulate.a = 0.45 if ghost else 1.0


func show_frame(anim, frame):
	if sprite.animation != anim:
		sprite.animation = anim
	sprite.pause()
	sprite.frame = clampi(frame, 0, sprite.sprite_frames.get_frame_count(anim) - 1)


func play_loop(anim):
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func take_damage():
	if invuln > 0 or is_dead:
		return
	health -= 1
	invuln = HURT_INVULN
	red_t = HURT_INVULN
	hurt_t = HURT_ANIM
	got_hurt.emit()
	if health <= 0:
		dead()


func dead():
	# the spawner hears died and deals with clearing the arena + the menus
	is_dead = true
	firing = false
	velocity = Vector2.ZERO
	sprite.modulate.a = 1.0
	outline.set_shader_parameter("outline_width", 1.0)
	sprite.play("death")
	died.emit()


func revive():
	is_dead = false
	health = max_health
	invuln = 1.5
	red_t = 0.0
	hurt_t = 0.0
	since_shot = 99.0
	firing = false
	position = start_pos
	outline.set_shader_parameter("outline_width", 0.0)
	sprite.play("idle")


func upgrade_level(id):
	return upgrade_levels.get(id, 0)


func apply_upgrade(id):
	upgrade_levels[id] = upgrade_level(id) + 1
	recalc_stats()


func reset_upgrades():
	upgrade_levels.clear()
	recalc_stats()


func recalc_stats():
	max_health = BASE_MAX_HEALTH + int(Upgrades.bonus("max_health", upgrade_level("max_health")))
	speed = BASE_SPEED * (1.0 + Upgrades.bonus("speed", upgrade_level("speed")))
	# 20% more shots per second = cooldown divided by 1.2
	shoot_cooldown = BASE_SHOOT_COOLDOWN / (1.0 + Upgrades.bonus("fire_rate", upgrade_level("fire_rate")))
	ball_bounces = BASE_BOUNCES + int(Upgrades.bonus("bounces", upgrade_level("bounces")))
	ball_speed = BASE_ARROW_SPEED * (1.0 + Upgrades.bonus("ball_speed", upgrade_level("ball_speed")))
	health = min(health, max_health)
