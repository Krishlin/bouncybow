extends CharacterBody2D

@export var max_bounces: int = 3

var direction = Vector2.ZERO
var speed: float = 800.0
var bounces = 0

func _physics_process(delta):
	var col = move_and_collide(direction*speed*delta)
	if col:
		var thing = col.get_collider()
		if thing.has_method("take_hit"):
			# boss
			# shield up = bounce off like a wall
			if !thing.is_shielded():
				if bounces >= 1:
					thing.take_hit()
				queue_free()
				return
		elif thing.is_in_group("enemies"):
			#has to bounce first or it doesnt kill
			if bounces>=1:
				thing.die()
			else:
				queue_free()
			return
		if bounces >= max_bounces:
			queue_free()
			return
		bounces+=1
		direction = direction.bounce(col.get_normal())
