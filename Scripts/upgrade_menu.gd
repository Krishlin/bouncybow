extends CanvasLayer

signal upgrade_chosen(id)

const UPGRADES = [
	{"id": "max_health", "title": "+1 Max Health", "desc": "Survive one more hit."},
	{"id": "speed", "title": "Swift Feet", "desc": "Move 15% faster."},
	{"id": "fire_rate", "title": "Quick Shot", "desc": "Shoot 20% more often."},
	{"id": "bounces", "title": "Extra Bounce", "desc": "Balls bounce one more time."},
	{"id": "ball_speed", "title": "Fast Ball", "desc": "Balls travel 20% faster."},
]


func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # game is paused so this needs to still run

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	var title = Label.new()
	title.text = "You fell! Choose an upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	# pick 3 random ones
	var list = UPGRADES.duplicate()
	list.shuffle()
	for i in 3:
		var u = list[i]
		var btn = Button.new()
		btn.text = u.title + "\n\n" + u.desc
		btn.custom_minimum_size = Vector2(340, 220)
		btn.add_theme_font_size_override("font_size", 28)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(picked.bind(u.id))
		row.add_child(btn)
		if i == 0:
			btn.grab_focus.call_deferred()


func picked(id):
	upgrade_chosen.emit(id)
	queue_free()
