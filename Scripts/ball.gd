extends CharacterBody2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(direction * speed * delta)
	if collision:
		direction = direction.bounce(collision.get_normal())
