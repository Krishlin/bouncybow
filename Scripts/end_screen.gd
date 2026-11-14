extends CanvasLayer
# big screen with a title and some buttons. used for the victory screen and for game over in endless

signal chosen(id)

# whoever makes the screen sets these before adding it to the scene
var title_text = ""
var title_color = Color.WHITE
var body_text = ""
var buttons = []  # list of [id, text]


func _ready():
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # game is paused so this needs to still run

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)

	var title = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", title_color)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 14)
	vbox.add_child(title)

	var body = Label.new()
	body.text = body_text
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_theme_font_size_override("font_size", 36)
	vbox.add_child(body)

	for i in buttons.size():
		var btn = Button.new()
		btn.text = buttons[i][1]
		btn.custom_minimum_size = Vector2(760, 90)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(picked.bind(buttons[i][0]))
		vbox.add_child(btn)
		if i == 0:
			btn.grab_focus.call_deferred()


func picked(id):
	queue_free()
	chosen.emit(id)
