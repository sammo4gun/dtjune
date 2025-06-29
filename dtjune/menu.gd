extends Control

func _ready() -> void:
	MainMenuMusic.play()

func _on_start_button_pressed() -> void:
	MainMenuMusic.stop()
	get_tree().change_scene_to_file("res://World.tscn")


func _on_how_to_play_pressed() -> void:
	get_tree().change_scene_to_file("res://howtoplay.tscn")
