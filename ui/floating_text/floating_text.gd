# Etiqueta de daño flotante: aparece en la posición del golpe y sube desapareciendo.
extends Marker2D

const COLOR_PLAYER_DAMAGE: Color = Color(1.0, 0.2, 0.2)
const PLAYER_DAMAGE_SCALE: Vector2 = Vector2(1.2, 1.2) # Ligeramente más grande para el daño al jugador
const FLOAT_DISTANCE: float = 50.0
const FLOAT_RANDOM_X: float = 20.0 # Deriva horizontal aleatoria para evitar solapamiento
const POP_DURATION: float = 0.2
const FLOAT_DURATION: float = 0.8
const FADE_DURATION: float = 0.3

@onready var _label: Label = $Label

func setup(amount: int, is_player: bool) -> void:
	_label.text = str(amount)
	
	var target_scale: Vector2
	
	if is_player:
		_label.modulate = COLOR_PLAYER_DAMAGE
		target_scale = PLAYER_DAMAGE_SCALE
	else:
		_label.modulate = Color.WHITE
		target_scale = Vector2.ONE

	var tween: Tween = create_tween().set_parallel(true)
	var drift := Vector2(randf_range(-FLOAT_RANDOM_X, FLOAT_RANDOM_X), -FLOAT_DISTANCE)
	tween.tween_property(self, "position", position + drift, FLOAT_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Aparece desde escala cero con efecto elástico
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", target_scale, POP_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.chain().tween_callback(queue_free)
