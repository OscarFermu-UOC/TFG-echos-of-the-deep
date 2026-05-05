# Nodo del mapa de run: representa un stage con su tipo y estado visual (completado, actual, futuro).
class_name MapNode
extends Control

enum Type { COMBAT, SANCTUARY }
enum Status { COMPLETED, CURRENT, FUTURE }

const COLOR_COMPLETED: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_CURRENT: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_FUTURE: Color = Color(0.5, 0.5, 0.6, 1.0)

const SCALE_FUTURE: Vector2  = Vector2(0.8, 0.8)
const SCALE_CURRENT: Vector2 = Vector2(1.2, 1.2)
const PULSE_SCALE_MAX: Vector2 = Vector2(1.3, 1.3)
const PULSE_SCALE_MIN: Vector2 = Vector2(1.1, 1.1)
const PULSE_DURATION: float = 0.5

@onready var _icon: TextureRect = $Icon

func setup(node_type: Type, status: Status, textures: Dictionary) -> void:
	match node_type:
		Type.COMBAT: _icon.texture = textures.combat
		Type.SANCTUARY: _icon.texture = textures.sanctuary

	match status:
		Status.COMPLETED:
			_icon.modulate = COLOR_COMPLETED
			_icon.scale = Vector2.ONE
		Status.FUTURE:
			_icon.modulate = COLOR_FUTURE
			_icon.scale = SCALE_FUTURE
		Status.CURRENT:
			_icon.modulate = COLOR_CURRENT
			_icon.scale = SCALE_CURRENT
			_play_pulse_animation()

func _play_pulse_animation() -> void:
	# Pulso en bucle para destacar el nodo actual
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_icon, "scale", PULSE_SCALE_MAX, PULSE_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_icon, "scale", PULSE_SCALE_MIN, PULSE_DURATION).set_trans(Tween.TRANS_SINE)
