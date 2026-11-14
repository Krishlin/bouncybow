extends CharacterBody2D

var direction = Vector2.ZERO
var speed = 350.0
var max_bounces = 3
var bounces = 0


func _ready():
	add_to_group("enemies") # so they get wiped when you die


func die():
	queue_free()


func _physics_process(delta):
	var hit = move_and_collide(direction * speed * delta)
	if hit == null:
		return

	var c = hit.get_collider()
	if c.has_method("take_damage"):
		# its the player
		c.take_damage()
		queue_free()
	elif c is StaticBody2D:
		if bounces >= max_bounces:
			queue_free()
			return
		bounces += 1
		direction = direction.bounce(hit.get_normal())
	else:
		add_collision_exception_with(c)  # player balls, ignore
