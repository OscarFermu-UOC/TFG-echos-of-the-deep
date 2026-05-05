# Icono de corazón individual: cambia de textura y reproduce animaciones al recibir daño o curar.
class_name HeartIcon
extends PanelContainer

const BREAK_FLASH_COLOR: Color = Color(10.0, 10.0, 10.0)
const BREAK_SHRINK_SCALE: Vector2 = Vector2(0.8, 0.8)
const BREAK_SHAKE_OFFSET: float = 3.0
const BREAK_SHAKE_STEP: float = 0.05
const BREAK_FLASH_IN: float = 0.1
const BREAK_FLASH_OUT: float = 0.2
const HEAL_POP_SCALE: Vector2 = Vector2(1.3, 1.3)
const HEAL_POP_DURATION: float = 0.15

@export var texture_full: Texture2D
@export var texture_half: Texture2D
@export var texture_empty: Texture2D

@onready var _icon: TextureRect = $CenterContainer/Icon

var _current_state: int = 2  # 2 = lleno, 1 = mitad, 0 = vacío

func update_heart(value: int) -> void:
	if value == _current_state:
		return

	if value < _current_state:
		_play_break_animation()
	else:
		_play_heal_animation()

	_current_state = value

	match value:
		2: _icon.texture = texture_full
		1: _icon.texture = texture_half
		_: _icon.texture = texture_empty

func _play_break_animation() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_icon, "position:x", _icon.position.x + BREAK_SHAKE_OFFSET, BREAK_SHAKE_STEP)
	tween.tween_property(_icon, "position:x", _icon.position.x - BREAK_SHAKE_OFFSET, BREAK_SHAKE_STEP)
	tween.tween_property(_icon, "position:x", _icon.position.x, BREAK_SHAKE_STEP)
	tween.parallel().tween_property(_icon, "modulate", BREAK_FLASH_COLOR, BREAK_FLASH_IN)
	tween.chain().tween_property(_icon, "modulate", Color.WHITE, BREAK_FLASH_OUT)
	tween.parallel().tween_property(_icon, "scale", BREAK_SHRINK_SCALE, BREAK_FLASH_IN)
	tween.chain().tween_property(_icon, "scale", Vector2.ONE, BREAK_FLASH_OUT).set_trans(Tween.TRANS_ELASTIC)

func _play_heal_animation() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_icon, "scale", HEAL_POP_SCALE, HEAL_POP_DURATION).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_icon, "scale", Vector2.ONE, HEAL_POP_DURATION)
