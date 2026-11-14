extends Node2D

var ENEMY = preload("res://Scenes/Enemy.tscn")
const HUD = preload("res://Scripts/hud.gd")
@export var player: Node2D
var spawn_time = 10.0
var timer = 0.0

var wave = 1
var enemies_to_spawn = 0  
var hud


func _ready():
	add_to_group("spawner")
	# HUD goes on the parent, not here: this node's child count is used to
	# tell when every enemy is dead.
	hud = HUD.new()
	hud.spawner = self
	hud.player = player
	get_parent().add_child.call_deferred(hud)
	start_wave()


# called when the player dies: go back to wave 1
func restart():
	wave = 1
	timer = 0.0
	start_wave()


func start_wave():
	enemies_to_spawn = 1 + wave * 2   # wave 1 = 3 enemies, wave 2 = 5, wave 3 = 7...
	print("Wave ", wave, " - ", enemies_to_spawn, " enemies")


func _process(delta):
	if not is_instance_valid(player):
		return

	if enemies_to_spawn > 0:
		timer += delta
		if timer >= spawn_time:
			timer = 0.0
			spawn_enemy()
			enemies_to_spawn -= 1
	else:
		check_wave()



func check_wave():
	if get_child_count() == 0:
		wave += 1
		start_wave()
		hud.show_wave_cleared(wave - 1, enemies_to_spawn)


func spawn_enemy():
	var enemy = ENEMY.instantiate()
	enemy.player = player

	var spot = Vector2(randf_range(150, 1800), randf_range(150, 950))
	while spot.distance_to(player.position) < 600:
		spot = Vector2(randf_range(150, 1800), randf_range(150, 950))

	enemy.position = spot
	add_child(enemy)
