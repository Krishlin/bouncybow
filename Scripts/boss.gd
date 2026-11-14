extends CharacterBody2D

signal defeated

const BULLET = preload("res://Scenes/boss_bullet.tscn")
const OUTLINE = preload("res://Scripts/outline.gdshader")

const BODY_RADIUS = 85.0
const SHIELD_RADIUS = 125.0
const TOUCH_RANGE = 125.0  # body 85 + player 30 + a bit extra
const INTRO_TIME = 1.5     # stands there for a sec before it starts so you can get ready

var player: Node2D
var tier = 1  # 1 = the wave 5 boss, 2 = wave 10, 3 = wave 15... the spawner sets it

var max_health = 18
var health = 18
var dead = false

# shooting = shield on, stands still and shoots arrows at you
# not shooting = no shield, walks around, this is when you can hit it
var shooting = true
var t = 0.0
var intro = INTRO_TIME
var shoot_time = 8.0
var walk_time = 7.0

var shot_t = 0.0
var shot_delay = 0.85
var ringTimer = 0.0
var ring_delay = 3.5
var ring_count = 8
var bullet_speed = 380.0  # players is 800
var bullet_bounces = 1

var spd = 240.0
var target = Vector2.ZERO
var flash = 0.0
var cast_t = 0.0  # holding the axe up after shooting
var outline: ShaderMaterial

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var shape: CircleShape2D = $CollisionShape2D.shape


func _ready():
	add_to_group("enemies")
	position = Vector2(960, 530)  # middle of the arena
	target = position
	scale_to_tier()

	outline = ShaderMaterial.new()
	outline.shader = OUTLINE
	sprite.material = outline
	sprite.play("idle")
	set_shield(true)


func scale_to_tier():
	# every boss after the first is a fixed % stronger than the one before it
	var n = tier - 1
	max_health = int(round(18.0 * pow(1.5, n)))        # 18, 27, 41, 61...
	health = max_health
	shoot_time = min(8.0 + n, 12.0)
	walk_time = max(7.0 - 0.5 * n, 4.5)
	shot_delay = max(0.85 * pow(0.85, n), 0.25)
	ring_delay = max(3.5 * pow(0.88, n), 1.5)
	ring_count = min(8 + 2 * n, 20)
	bullet_speed = min(380.0 * pow(1.12, n), 750.0)
	bullet_bounces = min(1 + n, 3)
	spd = min(240.0 * pow(1.1, n), 420.0)


func is_shielded():
	return shooting and not dead


func set_shield(on):
	shooting = on
	t = 0.0
	# the shield is a bigger circle so arrows bounce off where you can see it
	shape.radius = SHIELD_RADIUS if on else BODY_RADIUS
	cast_t = 0.0
	if on:
		shot_t = 0.0
		ringTimer = 0.0
		velocity = Vector2.ZERO
		sprite.play("idle")
	else:
		newTarget()
		sprite.play("walk")


func take_hit():
	if shooting or dead:
		return
	health -= 1
	flash = 0.18
	if health <= 0:
		die_for_real()


func die_for_real():
	dead = true
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	outline.set_shader_parameter("outline_width", 1.0)
	sprite.play("death")
	queue_redraw()
	defeated.emit()
	var tw = create_tween()
	tw.tween_interval(0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


func despawn():
	# player died, fight is over
	queue_free()


func _physics_process(delta):
	if dead or not is_instance_valid(player):
		return

	if intro > 0:
		intro -= delta
		queue_redraw()
		return

	t += delta

	if shooting:
		velocity = Vector2.ZERO
		if t >= shoot_time:
			set_shield(false)  # shield down
		else:
			shoot_stuff(delta)
	else:
		if t >= walk_time:
			set_shield(true)
		else:
			if position.distance_to(target) < 30:
				newTarget()
			velocity = position.direction_to(target) * spd

	move_and_slide()
	if !shooting and get_slide_collision_count() > 0:
		newTarget()  # hit something

	if shooting:
		sprite.flip_h = player.position.x < position.x
	elif velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	if player.position.distance_to(position) < TOUCH_RANGE:
		player.take_damage()

	if cast_t > 0:
		cast_t -= delta
		if cast_t <= 0:
			sprite.play("idle" if shooting else "walk")

	# red outline when it gets hit
	flash = max(flash - delta, 0.0)
	outline.set_shader_parameter("outline_width", 1.0 if flash > 0 else 0.0)

	queue_redraw()


func newTarget():
	target = Vector2(randf_range(250, 1670), randf_range(250, 810))


func shoot_stuff(delta):
	shot_t += delta
	ringTimer += delta

	if shot_t >= shot_delay:
		shot_t = 0
		shoot(position.direction_to(player.position))
		raise_axe(0.22)

	if ringTimer >= ring_delay:
		ringTimer = 0
		var off = randf()*TAU
		for i in ring_count:
			shoot(Vector2.RIGHT.rotated(off + TAU*i/ring_count))
		raise_axe(0.5)


func raise_axe(how_long):
	# frame 2 of the attack is the axe up in the air. the frames after it have a huge slash
	# effect that looks wrong for shooting, so just hold that one frame for a moment
	cast_t = max(cast_t, how_long)
	sprite.animation = "attack"
	sprite.pause()
	sprite.frame = 2


func shoot(dir):
	var b = BULLET.instantiate()
	b.direction = dir
	b.speed = bullet_speed
	b.max_bounces = bullet_bounces
	b.position = global_position + dir * (SHIELD_RADIUS + 20)
	get_parent().add_child(b)


func _draw():
	if dead:
		return
	if shooting:
		# shield
		draw_circle(Vector2.ZERO, SHIELD_RADIUS, Color(0.3, 0.7, 1, 0.25))
		draw_arc(Vector2.ZERO, SHIELD_RADIUS, 0, TAU, 48, Color(0.5,0.85,1,0.9), 5)
	elif t > walk_time - 1.0:
		# flickers for the last second of walking so you know the shield is about to come back
		if fmod(t, 0.2) < 0.1:
			draw_arc(Vector2.ZERO, SHIELD_RADIUS, 0, TAU, 48, Color(0.5,0.85,1,0.6), 4)
