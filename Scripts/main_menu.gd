extends Control


func _ready():
	# in case we got here from the pause menu
	get_tree().paused = false

	var how = Label.new()
	how.text = "WASD to move.  Hold left click to shoot.\nArrows only hurt enemies AFTER they bounce off a wall.\nEvery 5th wave is a boss.  Esc to pause."
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	how.add_theme_font_size_override("font_size", 28)
	how.modulate.a = 0.8
	$CenterContainer/VBoxContainer.add_child(how)


func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
