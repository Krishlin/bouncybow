extends Control


# Godot calls this when the Start button is clicked
func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainScene.tscn")
