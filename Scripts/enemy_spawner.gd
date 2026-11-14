extends Node2D

var ENEMY = preload("res://Scenes/Enemy.tscn")
@export var player: Node2D

var spawn_time = 2.0  
var max_enemies = 4   
var timer = 0.0


func _process(delta):
	timer += delta
	if timer >= spawn_time:
		timer = 0.0
		if get_child_count() < max_enemies:
			spawn_enemy()


func spawn_enemy():
	var enemy = ENEMY.instantiate()
	enemy.player = player
	
	var spot = Vector2(randf_range(150, 1800), randf_range(150, 950))
	while spot.distance_to(player.position) < 400:
		spot = Vector2(randf_range(150, 1800), randf_range(150, 950))
	
	enemy.position = spot
	add_child(enemy)
	
