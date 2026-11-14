extends CharacterBody2D
# arrows the boss shoots. red outline = bad, dodge these

const OUTLINE = preload("res://Scripts/outline.gdshader")

var direction = Vector2.ZERO
var speed = 380.0
var max_bounces = 1
var bounces = 0


func _ready():
	add_to_group("boss_bullets")  # so they get wiped when you die or the boss does
	rotation = direction.angle()
	var mat = ShaderMaterial.new()
	mat.shader = OUTLINE
	mat.set_shader_parameter("outline_width", 1.0)
	$Sprite2D.material = mat


func despawn():
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
		return

	# wall
	if bounces >= max_bounces:
		queue_free()
		return
	bounces += 1
	direction = direction.bounce(hit.get_normal())
	rotation = direction.angle()
