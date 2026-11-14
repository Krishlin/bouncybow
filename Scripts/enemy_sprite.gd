extends CharacterBody2D

signal died

@export var player: Node2D

const SPAWN_TIME = 0.5
const TOUCH_RANGE = 66.0  # our radius 26 + player radius 30 + a bit extra

var move_speed = 150.0    # the spawner sets this, later waves are faster
var knockback_strength = 1000
var kb_fade = 1500
var knockback = Vector2.ZERO
var spawn_t = SPAWN_TIME  # fades in first so it cant pop up and hit you instantly
var dying = false

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready():
	add_to_group("enemies")
	modulate.a = 0.0
	sprite.play("idle")
	sprite.animation_finished.connect(_on_anim_done)


func die():
	if dying:
		return
	dying = true
	# out of the group and no collision right away so arrows fly through and the wave can end
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	died.emit()
	sprite.play("death")
	var tw = create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)


func despawn():
	# arena getting cleared, no death animation
	queue_free()


func _on_anim_done():
	if not dying:
		sprite.play("walk")


func _physics_process(delta):
	if dying or not is_instance_valid(player):
		return

	if spawn_t > 0:
		spawn_t -= delta
		modulate.a = clampf(1.0 - spawn_t / SPAWN_TIME, 0.0, 1.0)
		if spawn_t <= 0:
			sprite.play("walk")
		return

	velocity = position.direction_to(player.position) * move_speed + knockback
	move_and_slide()
	knockback = knockback.move_toward(Vector2.ZERO, kb_fade * delta)
	sprite.flip_h = player.position.x < position.x

	if position.distance_to(player.position) < TOUCH_RANGE:
		knockback = player.position.direction_to(position) * knockback_strength
		player.take_damage()
		sprite.play("attack")
