extends CanvasLayer

signal upgrade_chosen(id)

const Upgrades = preload("res://Scripts/upgrades.gd")

# whoever makes the menu sets these before adding it to the scene
var title_text = "You fell! Choose an upgrade"
var levels = {}             # upgrade id -> how many times the player already has it
var wave = 1                # wave to restart at if they take the checkpoint
var allow_checkpoint = true


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
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	vbox.add_child(title)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(row)

	# pick 3 random ones. ones you already have can show up again
	var list = []
	for u in Upgrades.LIST:
		if u.id == "checkpoint" and not allow_checkpoint:
			continue
		list.append(u)
	list.shuffle()
	for i in 3:
		var u = list[i]
		var have = levels.get(u.id, 0)
		var btn = Button.new()
		var text = u.title
		if have > 0 and u.id != "checkpoint":
			text += "  (Lv %d)" % (have + 1)
		text += "\n\n" + Upgrades.card_desc(u.id, have, wave)
		btn.text = text
		btn.custom_minimum_size = Vector2(360, 240)
		btn.add_theme_font_size_override("font_size", 28)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(picked.bind(u.id))
		row.add_child(btn)
		if i == 0:
			btn.grab_focus.call_deferred()


func picked(id):
	Sfx.play("upgrade")
	upgrade_chosen.emit(id)
	queue_free()
