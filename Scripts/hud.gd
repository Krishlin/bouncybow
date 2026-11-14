extends CanvasLayer
## On-screen HUD: current wave + health in the corner, and a big
## "Wave cleared!" banner with a screen flash when a wave is beaten.

var spawner: Node
var player: Node

var info_label: Label
var flash: ColorRect
var banner: VBoxContainer
var banner_title: Label
var banner_sub: Label
var banner_tween: Tween


func _ready() -> void:
	layer = 5

	info_label = Label.new()
	info_label.position = Vector2(40, 30)
	info_label.add_theme_font_size_override("font_size", 36)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 8)
	add_child(info_label)

	flash = ColorRect.new()
	flash.color = Color(1, 0.9, 0.4, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	banner = VBoxContainer.new()
	banner.add_theme_constant_override("separation", 10)
	banner.modulate.a = 0.0
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(banner)

	banner_title = _make_label(96, Color(1, 0.85, 0.2))
	banner.add_child(banner_title)
	banner_sub = _make_label(40, Color.WHITE)
	banner.add_child(banner_sub)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 12)
	return label


func _process(_delta: float) -> void:
	if not is_instance_valid(spawner) or not is_instance_valid(player):
		return
	info_label.text = "Wave %d\nHealth %d / %d" % [spawner.wave, max(player.health, 0), player.max_health]


func show_wave_cleared(cleared_wave: int, next_count: int) -> void:
	banner_title.text = "WAVE %d CLEARED!" % cleared_wave
	banner_sub.text = "Wave %d incoming: %d enemies" % [cleared_wave + 1, next_count]

	if banner_tween:
		banner_tween.kill()
	banner.modulate.a = 0.0

	# Wait one frame so the banner resizes to the new text before we scale it.
	await get_tree().process_frame

	# Pop the banner in, hold it, then fade out.
	banner.pivot_offset = banner.size / 2
	banner.scale = Vector2(0.5, 0.5)
	banner.modulate.a = 0.0
	flash.color.a = 0.35

	banner_tween = create_tween().set_parallel(true)
	banner_tween.tween_property(flash, "color:a", 0.0, 0.5)
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.4) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	banner_tween.chain().tween_interval(2.0)
	banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.6)
