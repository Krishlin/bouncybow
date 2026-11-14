extends Node2D
# Runs the whole run: waves, the boss every 5th wave, and what happens when you die or win.

const ENEMY = preload("res://Scenes/Enemy.tscn")
const BossScene = preload("res://Scenes/boss.tscn")
const HUD = preload("res://Scripts/hud.gd")
const UpgradeMenu = preload("res://Scripts/upgrade_menu.gd")
const PauseMenu = preload("res://Scripts/pause_menu.gd")
const EndScreen = preload("res://Scripts/end_screen.gd")

# ---- balance numbers ----
# each one changes by a fixed % every wave, so the game gets exponentially harder
const BOSS_EVERY = 5
const FIRST_WAVE_ENEMIES = 4.0
const ENEMY_GROWTH = 1.3          # 30% more enemies every wave: 4, 5, 7, 9, boss, 15, 19, 25, 33...
const FIRST_SPAWN_DELAY = 1.8
const SPAWN_DELAY_SHRINK = 0.85   # 15% less time between spawns every wave
const MIN_SPAWN_DELAY = 0.2
const ENEMY_SPEED = 150.0
const ENEMY_SPEED_GROWTH = 1.07   # 7% faster every wave
const MAX_ENEMY_SPEED = 400.0     # stays under the players 480 so you can always outrun them
const MAX_ALIVE = 40              # more than this at once and the game would just lag
const WAVE_BREAK = 2.5            # breather between waves

enum { FIGHTING, BREAK, PLAYER_DEAD, BOSS_DEAD, MENU }

@export var player: Node2D

var state = FIGHTING
var state_t = 0.0

var wave = 1
var endless = false
var kills = 0
var enemies_to_spawn = 0
var spawn_delay = FIRST_SPAWN_DELAY
var timer = 0.0
var hud
var boss = null


func _ready():
	add_to_group("spawner")
	player.died.connect(_on_player_died)
	# hud goes on the main scene, not under us, only enemies and the boss live under the spawner
	hud = HUD.new()
	hud.spawner = self
	hud.player = player
	get_parent().add_child.call_deferred(hud)
	start_wave()


# ---------- wave numbers ----------

func is_boss_wave(w):
	return w % BOSS_EVERY == 0


func enemy_count(w):
	return int(round(FIRST_WAVE_ENEMIES * pow(ENEMY_GROWTH, w - 1)))


func spawn_delay_for(w):
	return max(FIRST_SPAWN_DELAY * pow(SPAWN_DELAY_SHRINK, w - 1), MIN_SPAWN_DELAY)


func enemy_speed(w):
	return min(ENEMY_SPEED * pow(ENEMY_SPEED_GROWTH, w - 1), MAX_ENEMY_SPEED)


func enemies_alive():
	return get_tree().get_nodes_in_group("enemies").size()


func enemies_left():
	return enemies_to_spawn + enemies_alive()


# ---------- waves ----------

func start_wave():
	state = FIGHTING
	if is_boss_wave(wave):
		enemies_to_spawn = 0
		boss = BossScene.instantiate()
		boss.player = player
		boss.tier = wave / BOSS_EVERY
		boss.defeated.connect(_on_boss_defeated)
		add_child(boss)
		return
	enemies_to_spawn = enemy_count(wave)
	spawn_delay = spawn_delay_for(wave)
	timer = max(spawn_delay - 0.5, 0.0)  # first one shows up almost right away


func _process(delta):
	if !is_instance_valid(player): return

	match state:
		FIGHTING:
			if enemies_to_spawn > 0:
				timer += delta
				if timer >= spawn_delay and enemies_alive() < MAX_ALIVE:
					timer = 0.0
					spawn_enemy()
					enemies_to_spawn -= 1
			elif enemies_alive() == 0:
				wave_cleared("WAVE %d CLEARED!" % wave)
		BREAK:
			state_t -= delta
			if state_t <= 0:
				start_wave()
		PLAYER_DEAD:
			# short wait so you see the death animation before the menu pops up
			state_t -= delta
			if state_t <= 0:
				show_death_menu()
		BOSS_DEAD:
			state_t -= delta
			if state_t <= 0:
				if endless:
					wave_cleared("BOSS DEFEATED!")
				else:
					show_victory()


func wave_cleared(title):
	wave += 1
	state = BREAK
	state_t = WAVE_BREAK
	if is_boss_wave(wave):
		hud.show_banner(title, "BOSS INCOMING!")
	else:
		hud.show_banner(title, "Wave %d incoming: %d enemies" % [wave, enemy_count(wave)])


func spawn_enemy():
	var e = ENEMY.instantiate()
	e.player = player
	# a bit of random so they dont all walk in one clump
	e.move_speed = enemy_speed(wave) * randf_range(0.9, 1.1)

	var spot = random_spot()
	# not too close to the player. gives up after 20 tries so it can never get stuck looping
	for i in 20:
		if spot.distance_to(player.position) >= 500:
			break
		spot = random_spot()
	e.position = spot
	e.died.connect(_on_enemy_died)
	add_child(e)


func random_spot():
	return Vector2(randf_range(150, 1770), randf_range(150, 910))


func _on_enemy_died():
	kills += 1


func clear_arena():
	enemies_to_spawn = 0
	get_tree().call_group("enemies", "despawn")
	get_tree().call_group("boss_bullets", "despawn")
	get_tree().call_group("arrows", "queue_free")


# ---------- boss ----------

func _on_boss_defeated():
	kills += 1
	get_tree().call_group("boss_bullets", "despawn")
	player.health = player.max_health  # full heal for winning
	state = BOSS_DEAD
	state_t = 1.6


func show_victory():
	state = MENU
	get_tree().paused = true
	hud.hide_banner()
	var s = EndScreen.new()
	s.title_text = "VICTORY!"
	s.title_color = Color(1, 0.85, 0.2)
	s.body_text = "You beat the boss!\nEnemies defeated: %d" % kills
	s.buttons = [
		["endless", "Endless Mode\nKeep your upgrades and see how far you get.\nBoss every 5 waves."],
		["new_run", "New Run\nStart over from wave 1 and try different upgrades."],
		["menu", "Main Menu"],
	]
	s.chosen.connect(_on_end_screen_choice)
	get_parent().add_child(s)


func _on_end_screen_choice(id):
	match id:
		"endless":
			endless = true
			get_tree().paused = false
			wave_cleared("ENDLESS MODE")
		"new_run":
			new_run()
		"menu":
			go_to_main_menu()


# ---------- dying ----------

func _on_player_died():
	state = PLAYER_DEAD
	state_t = 1.0
	clear_arena()


func show_death_menu():
	state = MENU
	get_tree().paused = true
	hud.hide_banner()
	if endless:
		# endless mode has no retries, this is the end of the run
		var s = EndScreen.new()
		s.title_text = "GAME OVER"
		s.title_color = Color(1, 0.35, 0.3)
		s.body_text = "You made it to wave %d in endless mode.\nEnemies defeated: %d" % [wave, kills]
		s.buttons = [
			["new_run", "New Run\nStart over from wave 1 and try different upgrades."],
			["menu", "Main Menu"],
		]
		s.chosen.connect(_on_end_screen_choice)
		get_parent().add_child(s)
		return

	var menu = UpgradeMenu.new()
	menu.title_text = "You fell on wave %d! Choose an upgrade" % wave
	menu.levels = player.upgrade_levels
	menu.wave = wave
	menu.allow_checkpoint = wave > 1  # pointless on wave 1
	menu.upgrade_chosen.connect(_on_death_upgrade)
	get_parent().add_child(menu)


func _on_death_upgrade(id):
	player.apply_upgrade(id)
	# checkpoint = try the same wave again, anything else = back to the start
	if id != "checkpoint":
		wave = 1
	begin_attempt()


func new_run():
	# fresh start: no upgrades, wave 1, but you get to pick one upgrade to start with
	clear_arena()
	player.reset_upgrades()
	endless = false
	wave = 1
	kills = 0
	state = MENU
	get_tree().paused = true
	var menu = UpgradeMenu.new()
	menu.title_text = "New run! Pick an upgrade to start with"
	menu.levels = player.upgrade_levels
	menu.wave = wave
	menu.allow_checkpoint = false
	menu.upgrade_chosen.connect(_on_start_upgrade)
	get_parent().add_child(menu)


func _on_start_upgrade(id):
	player.apply_upgrade(id)
	begin_attempt()


func begin_attempt():
	player.revive()
	get_tree().paused = false
	start_wave()
	if is_boss_wave(wave):
		hud.show_banner("WAVE %d" % wave, "BOSS FIGHT!")
	else:
		hud.show_banner("WAVE %d" % wave, "%d enemies" % enemy_count(wave))


func go_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


# ---------- pausing ----------

func _unhandled_input(event):
	# Esc or P. we dont get input while the game is paused, so this only ever opens the menu
	var esc = event.is_action_pressed("ui_cancel")
	var p = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_P
	if (esc or p) and (state == FIGHTING or state == BREAK):
		get_viewport().set_input_as_handled()
		open_pause_menu()


func open_pause_menu():
	get_tree().paused = true
	var menu = PauseMenu.new()
	menu.spawner = self
	menu.player = player
	get_parent().add_child(menu)
