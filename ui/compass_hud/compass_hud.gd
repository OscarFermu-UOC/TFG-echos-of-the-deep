# HUD de brújula: rota una flecha hacia el objetivo actual marcado por GlobalData.
extends CanvasLayer

const COMPASS_OFFSET_ANGLE: float = 0.0 # El sprite apunta hacia arriba, compensamos 90° al calcular la dirección
const TARGET_PULSE_SCALE: Vector2 = Vector2(4.2, 4.2)
const RESTING_SCALE: Vector2 = Vector2(4.0, 4.0)
const PULSE_DURATION: float = 0.1

@onready var _compass: Sprite2D = %CompassArrow

var _target_node: Node = null
var _player: Node2D = null

func _ready() -> void:
	EventBus.compass_target_changed.connect(_on_target_changed)
	
	if GlobalData.target:
		_target_node = GlobalData.target

	_player = get_tree().get_first_node_in_group("Player")

func _on_target_changed() -> void:
	_target_node = GlobalData.target
	
	# Pulso de escala para avisar al jugador de que el objetivo ha cambiado
	var tween: Tween = create_tween()
	tween.tween_property(_compass, "scale", TARGET_PULSE_SCALE, PULSE_DURATION)
	tween.tween_property(_compass, "scale", RESTING_SCALE, PULSE_DURATION)

func _process(_delta: float) -> void:
	if not _player or not _target_node or not is_instance_valid(_target_node):
		return
		
	var direction: Vector2 = _target_node.global_position - _player.global_position
	_compass.rotation = direction.angle() + deg_to_rad(COMPASS_OFFSET_ANGLE)
