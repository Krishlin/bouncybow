extends CanvasLayer
## Pause menu shown when the player runs out of health.
## Offers 3 random upgrades; picking one applies it and resumes the game.

signal upgrade_chosen(id: String)

const UPGRADES = [
	{"id": "max_health", "title": "+1 Max Health", "desc": "Survive one more hit."},
	{"id": "speed", "title": "Swift Feet", "desc": "Move 15% faster."},
	{"id": "fire_rate", "title": "Quick Shot", "desc": "Shoot 20% more often."},
	{"id": "bounces", "title": "Extra Bounce", "desc": "Balls bounce one more time."},
	{"id": "ball_speed", "title": "Fast Ball", "desc": "Balls travel 20% faster."},
]


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 40)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "You fell! Choose an upgrade"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	var pool := UPGRADES.duplicate()
	pool.shuffle()
	for i in 3:
		var upgrade: Dictionary = pool[i]
		var button := Button.new()
		button.text = "%s\n\n%s" % [upgrade.title, upgrade.desc]
		button.custom_minimum_size = Vector2(340, 220)
		button.add_theme_font_size_override("font_size", 28)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_pick.bind(upgrade.id))
		row.add_child(button)
		if i == 0:
			button.grab_focus.call_deferred()


func _on_pick(id: String) -> void:
	upgrade_chosen.emit(id)
	queue_free()
