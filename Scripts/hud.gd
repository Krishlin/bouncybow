extends CanvasLayer
# wave + health text in the corner and the big wave cleared thing

var spawner
var player

var info_label
var flash
var banner
var banner_title
var banner_sub
var tw


func _ready():
	layer = 5

	info_label = Label.new()
	info_label.position = Vector2(40, 30)
	info_label.add_theme_font_size_override("font_size", 36)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 8)
	add_child(info_label)

	# yellow screen flash
	flash = ColorRect.new()
	flash.color = Color(1, 0.9, 0.4, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	banner = VBoxContainer.new()
	banner.add_theme_constant_override("separation", 10)
	banner.modulate.a = 0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(banner)

	banner_title = make_label(96, Color(1, 0.85, 0.2))
	banner.add_child(banner_title)
	banner_sub = make_label(40, Color.WHITE)
	banner.add_child(banner_sub)


func make_label(size, col):
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 12)
	return l


func _process(_delta):
	if not is_instance_valid(spawner) or not is_instance_valid(player):
		return
	var txt = "Wave " + str(spawner.wave) + "\nHealth " + str(max(player.health, 0)) + " / " + str(player.max_health)
	if is_instance_valid(spawner.boss):
		txt += "\nBoss " + str(spawner.boss.health) + " / " + str(spawner.boss.max_health)
		if spawner.boss.is_shielded():
			txt += "  (SHIELDED)"
	info_label.text = txt


func show_wave_cleared(cleared_wave, next_count):
	banner_title.text = "WAVE %d CLEARED!" % cleared_wave
	if cleared_wave + 1 == spawner.boss_wave:
		banner_sub.text = "BOSS INCOMING!"
	else:
		banner_sub.text = "Wave %d incoming: %d enemies" % [cleared_wave + 1, next_count]

	if tw:
		tw.kill()
	banner.modulate.a = 0

	# wait a frame or the size is wrong
	await get_tree().process_frame

	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.5, 0.5)
	banner.modulate.a = 0
	flash.color.a = 0.35

	tw = create_tween().set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(2.0)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.6)
