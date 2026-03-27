# Estado de espera del Hunter: orbita al jugador a distancia antes de telegrafiar el ataque.
extends State
class_name HunterHover

const HOVER_STANDOFF_DISTANCE: float = 100.0  # Distancia que mantiene respecto al jugador
const HOVER_VELOCITY_LERP: float = 0.05 # Suavidad del movimiento (valor bajo = más flotante)

@export var hunter: Hunter
var timer: float = 0.0

func enter() -> void:
	hunter.hitbox.monitoring = false
	hunter.modulate.a = 0.5 # Semi-transparente para indicar que no es vulnerable
	timer = hunter.hover_duration

func physics_update(delta) -> void:
	if not hunter.player: return
	
	timer -= delta
	if timer <= 0.0:
		transitioned.emit(self, "Telegraph")
		return

	# Se posiciona detrás del vector jugador para mantenerse a distancia
	var dir_to_player: Vector2 = hunter.global_position.direction_to(hunter.player.global_position)
	var target_pos: Vector2 = hunter.player.global_position - (dir_to_player * HOVER_STANDOFF_DISTANCE)
	var target_vel: Vector2 = hunter.global_position.direction_to(target_pos) * hunter.hover_speed
	
	hunter.velocity = hunter.velocity.lerp(target_vel, HOVER_VELOCITY_LERP)
	hunter.move_and_slide()
	
	hunter.face_player()
