# Controlador de la cámara principal del juego.
extends Camera2D

# Offset que se va a aplicar a la cámara respecto al jugador
var desired_offset: Vector2
var min_offset: int = -10
var max_offset: int = 10

var player: Node2D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _process(_delta: float) -> void:
	# El offset se calcula en función de dónde está el ratón, al 50% para suavizarlo
	desired_offset = (get_global_mouse_position() - position) * 0.5
	desired_offset.x = clamp(desired_offset.x, min_offset, max_offset)
	# El eje Y tiene la mitad de rango que el X para que no se mueva tanto verticalmente
	desired_offset.y = clamp(desired_offset.y, min_offset / 2.0, max_offset / 2.0)
	global_position = player.global_position + desired_offset
