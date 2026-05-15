# Gestiona las transiciones entre escenas.
extends CanvasLayer

const DISSOLVE_ANIM: String = "dissolve"

@onready var _anim_player: AnimationPlayer = $AnimationPlayer

func change_scene_to_file(target: String) -> void:
	# Esperamos a que termine el fade out antes de cambiar de escena
	_anim_player.play(DISSOLVE_ANIM)
	await _anim_player.animation_finished
	get_tree().change_scene_to_file(target)
	_anim_player.play_backwards(DISSOLVE_ANIM) # Fade in en la nueva escena
