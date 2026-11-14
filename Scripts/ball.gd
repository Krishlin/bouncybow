extends CharacterBody2D
# The player's arrow. It can't hurt anything until it has bounced off a wall once.
# After the first bounce it's "armed": it glows gold and kills what it touches.

@export var max_bounces: int = 3

const DULL = Color(0.75, 0.75, 0.8)
const ARMED = Color(1.6, 1.35, 0.5)   # over 1 so it looks bright
const TRAIL_POINTS = 9

var direction = Vector2.ZERO
var speed: float = 800.0
var bounces = 0
var trail: Line2D

@onready var sprite = $Sprite2D


func _ready():
	add_to_group("arrows")
	rotation = direction.angle()
	sprite.modulate = DULL

	# fading line behind the arrow. top_level so it stays put in the world instead of turning with us
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 7
	trail.z_index = -1
	var fade = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0.7))
	trail.gradient = fade
	trail.default_color = Color.WHITE
	trail.modulate = DULL
	add_child(trail)
	trail.global_position = Vector2.ZERO


func _physics_process(delta):
	var col = move_and_collide(direction * speed * delta)

	trail.add_point(global_position)
	if trail.get_point_count() > TRAIL_POINTS:
		trail.remove_point(0)

	if col == null:
		# shouldnt happen but dont let one fly forever if it ever gets out of the arena
		if position.x < -200 or position.x > 2120 or position.y < -200 or position.y > 1260:
			queue_free()
		return

	var thing = col.get_collider()
	if thing.has_method("take_hit"):
		if not thing.is_shielded():
			if bounces >= 1:
				thing.take_hit()
			queue_free()
			return
	elif thing.is_in_group("enemies"):
		# has to bounce first or it doesnt kill
		if bounces >= 1:
			thing.die()  # the arrow keeps going so one good shot can get a few of them
		else:
			queue_free()
		return
	elif not (thing is StaticBody2D):
		# something thats already dying, fly through it
		add_collision_exception_with(thing)
		return

	if bounces >= max_bounces:
		queue_free()
		return
	bounces += 1
	direction = direction.bounce(col.get_normal())
	rotation = direction.angle()
	if bounces == 1:
		sprite.modulate = ARMED
		trail.modulate = ARMED
