extends CanvasLayer
# wave + hearts in the corner, the boss health bar, and the big banner in the middle

var spawner
var player

var info_label
var hearts
var flash
var banner
var banner_title
var banner_sub
var tw
var flash_tw
var boss_box
var boss_bar
var boss_label
var bar_fill: StyleBoxFlat


# little row of hearts, one per max health
class Hearts extends Control:
	var health = 0
	var max_health = 0

	func set_values(h, m):
		if h != health or m != max_health:
			health = h
			max_health = m
			queue_redraw()

	func _draw():
		for i in max_health:
			var col = Color(0.95, 0.2, 0.25) if i < health else Color(0.15, 0.15, 0.18)
			draw_heart(Vector2(22 + i * 50, 22), 1.25, col)

	func draw_heart(center, size, col):
		# the classic heart curve
		var outline_pts = PackedVector2Array()
		var pts = PackedVector2Array()
		for i in 24:
			var a = TAU * i / 24.0
			var x = 16.0 * pow(sin(a), 3)
			var y = -(13.0 * cos(a) - 5.0 * cos(2 * a) - 2.0 * cos(3 * a) - cos(4 * a))
			pts.append(center + Vector2(x, y) * size)
			outline_pts.append(center + Vector2(x, y) * (size + 0.22))
		draw_colored_polygon(outline_pts, Color.BLACK)
		draw_colored_polygon(pts, col)


func _ready():
	layer = 5

	info_label = Label.new()
	info_label.position = Vector2(48, 44)
	info_label.add_theme_font_size_override("font_size", 36)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 8)
	add_child(info_label)

	hearts = Hearts.new()
	hearts.position = Vector2(48, 150)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hearts)

	var hint = Label.new()
	hint.text = "Esc - pause"
	hint.position = Vector2(48, 975)
	hint.modulate.a = 0.6
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_outline_color", Color.BLACK)
	hint.add_theme_constant_override("outline_size", 6)
	add_child(hint)

	make_boss_bar()

	# screen flash. yellow for wave cleared, red for getting hit
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

	if is_instance_valid(player):
		player.got_hurt.connect(hurt_flash)


func make_label(size, col):
	var l = Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 12)
	return l


func make_boss_bar():
	boss_box = VBoxContainer.new()
	boss_box.position = Vector2(960 - 350, 48)  # top middle, the bar is 700 wide
	boss_box.custom_minimum_size = Vector2(700, 0)
	boss_box.add_theme_constant_override("separation", 6)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_box.visible = false
	add_child(boss_box)

	boss_bar = ProgressBar.new()
	boss_bar.custom_minimum_size = Vector2(700, 30)
	boss_bar.show_percentage = false
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.08, 0.1, 0.9)
	bg.set_border_width_all(3)
	bg.border_color = Color.BLACK
	boss_bar.add_theme_stylebox_override("background", bg)
	bar_fill = StyleBoxFlat.new()
	bar_fill.set_border_width_all(3)
	bar_fill.border_color = Color.BLACK
	boss_bar.add_theme_stylebox_override("fill", bar_fill)
	boss_box.add_child(boss_bar)

	boss_label = make_label(26, Color.WHITE)
	boss_label.add_theme_constant_override("outline_size", 8)
	boss_box.add_child(boss_label)


func _process(_delta):
	if not is_instance_valid(spawner) or not is_instance_valid(player):
		return

	var txt = "Wave " + str(spawner.wave)
	if spawner.endless:
		txt += "  (Endless)"
	if spawner.state == spawner.BREAK:
		txt += "\nGet ready..."
	elif spawner.is_boss_wave(spawner.wave):
		txt += "\nBoss fight!"
	else:
		txt += "\nEnemies left: " + str(spawner.enemies_left())
	info_label.text = txt

	hearts.set_values(max(player.health, 0), player.max_health)

	var b = spawner.boss
	if is_instance_valid(b) and not b.dead:
		boss_box.visible = true
		boss_bar.max_value = b.max_health
		boss_bar.value = b.health
		if b.is_shielded():
			bar_fill.bg_color = Color(0.35, 0.65, 1)
			boss_label.text = "SHIELD UP - dodge the red arrows!"
		else:
			bar_fill.bg_color = Color(0.9, 0.2, 0.2)
			boss_label.text = "SHIELD DOWN - bounce arrows into it!"
	else:
		boss_box.visible = false


func hurt_flash():
	if flash_tw:
		flash_tw.kill()
	flash.color = Color(1, 0.1, 0.1, 0.3)
	flash_tw = create_tween()
	flash_tw.tween_property(flash, "color:a", 0.0, 0.35)


func hide_banner():
	# so an old banner isnt stuck on screen behind a menu
	if tw:
		tw.kill()
	banner.modulate.a = 0
	flash.color.a = 0


func show_banner(title, sub):
	banner_title.text = title
	banner_sub.text = sub

	if tw:
		tw.kill()
	banner.modulate.a = 0

	# wait a frame or the size is wrong
	await get_tree().process_frame

	if flash_tw:
		flash_tw.kill()
	if tw:
		tw.kill()  # another banner could have started while we waited
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.5, 0.5)
	banner.modulate.a = 0
	flash.color = Color(1, 0.9, 0.4, 0.35)

	tw = create_tween().set_parallel(true)
	tw.tween_property(flash, "color:a", 0.0, 0.5)
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_property(banner, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.6)
	tw.chain().tween_property(banner, "modulate:a", 0.0, 0.6)
