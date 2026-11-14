extends CharacterBody2D

@export var player: Node2D

var move_speed = 180  # dont scale this, speed upgrade needs to matter
var knockback_strength = 1000
var kb_fade = 1500
var knockback = Vector2.ZERO


func _ready():
	add_to_group("enemies")


func die():
	queue_free()


func _physics_process(delta):
	if not is_instance_valid(player):
		return
	velocity = position.direction_to(player.position)*move_speed + knockback
	move_and_slide()
	knockback = knockback.move_toward(Vector2.ZERO, kb_fade*delta)

	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == player:
			knockback = player.position.direction_to(position) * knockback_strength
			player.take_damage()
			break
