extends CharacterBody2D

@export var max_bounces: int = 3

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0
var bounces: int = 0

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var collider = collision.get_collider()
		if collider.is_in_group("enemies"):
			# Enemies only die if the ball has bounced off a wall first.
			# Otherwise the ball just disappears.
			if bounces >= 1:
				collider.die()
			else:
				queue_free()
			return
		if bounces >= max_bounces:
			queue_free()
			return
		bounces += 1
		direction = direction.bounce(collision.get_normal())
