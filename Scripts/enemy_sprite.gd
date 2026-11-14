extends CharacterBody2D

@export var player: Node2D

var knockback_strength = 600  
var knockback_fade = 1500     
var knockback = Vector2.ZERO  


func _ready():
	add_to_group("enemies")


func die():
	queue_free()


func _physics_process(delta):
	if not is_instance_valid(player):
		return
	var speed = player.speed * 0.5
	velocity = position.direction_to(player.position) * speed + knockback
	move_and_slide()

	
	knockback = knockback.move_toward(Vector2.ZERO, knockback_fade * delta)


	for i in get_slide_collision_count():
		if get_slide_collision(i).get_collider() == player:
			knockback = player.position.direction_to(position) * knockback_strength
			player.take_damage()
			break
