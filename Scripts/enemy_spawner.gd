extends Node2D

var ENEMY = preload("res://Scenes/Enemy.tscn")
const HUD = preload("res://Scripts/hud.gd")
var BossScene = preload("res://Scenes/boss.tscn")
@export var player: Node2D
var spawn_time = 10.0
var timer = 0.0

var wave = 1
var enemies_to_spawn = 0
var hud
var boss_wave = 5
var boss = null


func _ready():
	add_to_group("spawner")
	# dont put hud as a child of this!! child count is how we know enemies are dead
	hud = HUD.new()
	hud.spawner = self
	hud.player = player
	get_parent().add_child.call_deferred(hud)
	start_wave()


func restart():
	# player died, back to wave 1
	wave = 1
	timer = 0
	start_wave()


func start_wave():
	if wave == boss_wave:
		enemies_to_spawn = 0
		boss = BossScene.instantiate()
		boss.player = player
		add_child(boss)
		print("BOSS TIME")
		return
	enemies_to_spawn = 1 + wave*2   # 3, 5, 7...
	print("Wave ", wave, " - ", enemies_to_spawn, " enemies")


func _process(delta):
	if !is_instance_valid(player): return

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
		hud.show_wave_cleared(wave-1, enemies_to_spawn)


func spawn_enemy():
	var e = ENEMY.instantiate()
	e.player = player

	var spot = Vector2(randf_range(150, 1800), randf_range(150, 950))
	# not too close to the player
	while spot.distance_to(player.position) < 600:
		spot = Vector2(randf_range(150,1800), randf_range(150,950))
	e.position = spot
	add_child(e)
