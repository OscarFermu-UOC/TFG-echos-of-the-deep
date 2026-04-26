#Menu princial - WIP
extends Control

@export var player_class: CharacterClass

func _on_btn_play_pressed() -> void:
	GlobalData.start_new_run_session(player_class)
	get_tree().change_scene_to_file("res://scenes/run/run.tscn")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
