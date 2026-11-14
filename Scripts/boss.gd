extends CharacterBody2D

var BULLET = preload("res://Scenes/boss_bullet.tscn")

var player: Node2D

var max_health = 25
var health = 25

# shooting = shield on, stands still, shoots for 30s
# not shooting = no shield, walks around for 10s, can hit it
var shooting = true
var t = 0.0
var shoot_time = 30.0
var walk_time = 10.0

var shot_t = 0.0
var shot_delay = 0.9
var ringTimer = 0.0
var ring_delay = 4.5
var ring_count = 8
var bullet_speed = 350.0  # players is 800

var spd = 260
var target = Vector2.ZERO
var flash = 0.0

@onready var sprite = $Sprite2D


func _ready():
	add_to_group("enemies")
	position = Vector2(960, 530)  # middle of the arena
	target = position


func is_shielded():
	return shooting


func take_hit():
	if shooting:
		return
	health -= 1
	flash = 0.12
	print("boss hp ", health)
	if health <= 0:
		queue_free()


func die():
	queue_free()


func _physics_process(delta):
	if not is_instance_valid(player):
		return

	t += delta

	if shooting:
		velocity = Vector2.ZERO
		if t >= shoot_time:
			# shield down
			shooting = false
			t = 0
			newTarget()
		else:
			shoot_stuff(delta)
	else:
		if t >= walk_time:
			shooting = true
			t = 0
			shot_t = 0
			ringTimer = 0
			velocity = Vector2.ZERO
		else:
			if position.distance_to(target) < 30:
				newTarget()
			velocity = position.direction_to(target) * spd

	move_and_slide()
	if !shooting and get_slide_collision_count() > 0:
		newTarget()  # hit something

	# 100 boss radius + 64 half the player roughly
	if player.position.distance_to(position) < 160:
		player.take_damage()

	if flash > 0:
		flash -= delta
		sprite.modulate = Color(3,3,3)
	else:
		sprite.modulate = Color(0.7, 0.3, 1)

	queue_redraw()


func newTarget():
	target = Vector2(randf_range(250, 1670), randf_range(250, 810))


func shoot_stuff(delta):
	shot_t += delta
	ringTimer += delta

	if shot_t >= shot_delay:
		shot_t = 0
		shoot(position.direction_to(player.position))

	if ringTimer >= ring_delay:
		ringTimer = 0
		var off = randf()*TAU
		for i in ring_count:
			shoot(Vector2.RIGHT.rotated(off + TAU*i/ring_count))


func shoot(dir):
	var b = BULLET.instantiate()
	b.add_collision_exception_with(self)
	b.direction = dir
	b.speed = bullet_speed
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + dir*120


func _draw():
	if shooting:
		# shield
		draw_circle(Vector2.ZERO, 140, Color(0.3, 0.7, 1, 0.25))
		draw_arc(Vector2.ZERO, 140, 0, TAU, 48, Color(0.5,0.85,1,0.9), 5)
