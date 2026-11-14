extends CanvasLayer
# pause screen: shows every upgrade you have, resume, or quit to the main menu

const Upgrades = preload("res://Scripts/upgrades.gd")

var spawner
var player


func _ready():
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS  # game is paused so this needs to still run

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var where = "Wave %d" % spawner.wave
	if spawner.endless:
		where += "  (Endless)"
	vbox.add_child(make_label("PAUSED", 80))
	vbox.add_child(make_label(where, 32))
	vbox.add_child(make_label("Your upgrades", 40))

	# one line per upgrade, in the same order as the upgrade list
	var lines = ""
	for u in Upgrades.LIST:
		var have = player.upgrade_level(u.id)
		if have == 0:
			continue
		if lines != "":
			lines += "\n"
		if u.id == "checkpoint":
			lines += "%s  -  %s" % [u.title, Upgrades.owned_desc(u.id, have)]
		else:
			lines += "%s  Lv %d  -  %s" % [u.title, have, Upgrades.owned_desc(u.id, have)]
	if lines == "":
		lines = "None yet. You get to pick one every time you die."
	vbox.add_child(make_label(lines, 28))

	var resume = make_button("Resume")
	resume.pressed.connect(resume_game)
	vbox.add_child(resume)
	resume.grab_focus.call_deferred()

	var quit = make_button("Main Menu  (restarts the whole game)")
	quit.pressed.connect(quit_to_menu)
	vbox.add_child(quit)


func make_label(text, size):
	var l = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	return l


func make_button(text):
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(560, 80)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 32)
	return b


func _unhandled_input(event):
	# Esc or P again closes it
	var esc = event.is_action_pressed("ui_cancel")
	var p = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_P
	if esc or p:
		get_viewport().set_input_as_handled()
		resume_game()


func resume_game():
	get_tree().paused = false
	queue_free()


func quit_to_menu():
	# going back to the menu throws away the run, upgrades and all
	queue_free()
	spawner.go_to_main_menu()
