# HUD de estado (block): muestra y anima los contadores de clank block y hazard block.
extends CanvasLayer
 
const POP_SCALE_TARGET: Vector2 = Vector2(1.5, 1.5)
const POP_SCALE_IN: float = 0.1
const POP_SCALE_OUT: float = 0.2
const POP_FLASH_COLOR: Color = Color(1.5, 1.5, 1.5)
const SHAKE_STEP: float = 0.05
const SHAKE_ANGLE: float = 15.0
const SHAKE_ANGLE_MID: float = 10.0
const SHAKE_FLASH_COLOR: Color = Color(3.0, 0.5, 0.5) # Flash rojo al perder bloqueo
const SHAKE_FLASH_IN: float = 0.1
const SHAKE_FLASH_OUT: float = 0.2
 
@onready var _clank_widget: HBoxContainer = %ClankBlockWidget
@onready var _clank_icon: TextureRect = %ClankIcon
@onready var _clank_label: Label = %ClankLabel
@onready var _hazard_widget: HBoxContainer = %HazardBlockWidget
@onready var _hazard_icon: TextureRect = %HazardIcon
@onready var _hazard_label: Label = %HazardLabel
 
var _last_clank_block: int = 0
var _last_hazard_block: int = 0
 
func _ready() -> void:
	EventBus.clank_block_changed.connect(_on_clank_block_changed)
	EventBus.hazard_block_changed.connect(_on_hazard_block_changed)
	_clank_widget.visible = false
	_hazard_widget.visible = false
 
func _on_clank_block_changed(new_amount: int) -> void:
	_clank_label.text = str(new_amount)
	_clank_widget.visible = new_amount > 0
	_play_delta_anim(_clank_icon, new_amount, _last_clank_block)
	_last_clank_block = new_amount
 
func _on_hazard_block_changed(new_amount: int) -> void:
	_hazard_label.text = str(new_amount)
	_hazard_widget.visible = new_amount > 0
	_play_delta_anim(_hazard_icon, new_amount, _last_hazard_block)
	_last_hazard_block = new_amount
 
# Decide qué animación reproducir comparando el valor nuevo con el anterior
func _play_delta_anim(target: Control, new_amount: int, last_amount: int) -> void:
	if new_amount > last_amount:
		_play_pop_anim(target)
	elif new_amount < last_amount:
		_play_shake_anim(target)

# Pop de escala + flash blanco al ganar bloqueo
func _play_pop_anim(target: Control) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(target, "scale", POP_SCALE_TARGET, POP_SCALE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(target, "modulate", POP_FLASH_COLOR, POP_SCALE_IN)
	tween.chain().tween_property(target, "scale", Vector2.ONE, POP_SCALE_OUT)
	tween.chain().tween_property(target, "modulate", Color.WHITE, POP_SCALE_OUT)
 
# Shake rotacional + flash rojo al perder bloqueo
func _play_shake_anim(target: Control) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(target, "rotation_degrees", SHAKE_ANGLE, SHAKE_STEP)
	tween.tween_property(target, "rotation_degrees", -SHAKE_ANGLE, SHAKE_STEP)
	tween.tween_property(target, "rotation_degrees", SHAKE_ANGLE_MID, SHAKE_STEP)
	tween.tween_property(target, "rotation_degrees", -SHAKE_ANGLE_MID, SHAKE_STEP)
	tween.tween_property(target, "rotation_degrees", 0.0, SHAKE_STEP)
	tween.parallel().tween_property(target, "modulate", SHAKE_FLASH_COLOR, SHAKE_FLASH_IN)
	tween.chain().tween_property(target, "modulate", Color.WHITE, SHAKE_FLASH_OUT)
