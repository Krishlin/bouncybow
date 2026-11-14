extends Node
# Autoload "Sfx". Plays sound effects from anywhere: Sfx.play("shoot")
# and the looping boss music: Sfx.start_music() / Sfx.stop_music()

const SOUNDS = {
	"shoot": preload("res://Sound Effects/Shooting Arrow.mp3"),
	"hit": preload("res://Sound Effects/Hit Enemy.mp3"),
	"wave_complete": preload("res://Sound Effects/Wave Complete.mp3"),
	"wave_lost": preload("res://Sound Effects/Wave Lost.mp3"),
	"upgrade": preload("res://Sound Effects/Choose Upgrade.mp3"),
	"victory": preload("res://Sound Effects/Final Boss Win.mp3"),
}
# quieter for the ones that happen a lot so they dont drown everything out
const VOLUME = {"shoot": -8.0, "hit": -3.0}
const BOSS_MUSIC = preload("res://Sound Effects/Boss Fight.mp3")
const POOL_SIZE = 12

var pool = []
var next = 0
var music: AudioStreamPlayer


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # menus play sounds while the game is paused
	for i in POOL_SIZE:
		var p = AudioStreamPlayer.new()
		add_child(p)
		pool.append(p)
	music = AudioStreamPlayer.new()
	var loop_stream = BOSS_MUSIC.duplicate()
	loop_stream.loop = true
	music.stream = loop_stream
	music.volume_db = -4.0
	add_child(music)


func play(sound_name):
	if not SOUNDS.has(sound_name):
		return
	# round robin so lots of shots at once can overlap
	var p = pool[next]
	next = (next + 1) % POOL_SIZE
	p.stream = SOUNDS[sound_name]
	p.volume_db = VOLUME.get(sound_name, 0.0)
	p.play()


func start_music():
	if not music.playing:
		music.play()


func stop_music():
	music.stop()
