extends Control


func _on_start_button_pressed() -> void:
	MainMenuMusic.stop()
	get_tree().change_scene_to_file("res://World.tscn")
