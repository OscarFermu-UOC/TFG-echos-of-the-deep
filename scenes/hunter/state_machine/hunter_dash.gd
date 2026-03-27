# Estado de embestida del Hunter: se lanza en línea recta hacia el jugador con la hitbox activa.
extends State
class_name HunterDash

const DASH_EXIT_DISTANCE: float = 600.0 # Distancia a la que se considera que el dash terminó

@export var hunter: Hunter
var dash_direction: Vector2

func enter() -> void:
	hunter.hitbox.monitoring = true
	
	# La dirección se fija al entrar; el dash no corrige la trayectoria
	if hunter.player:
		dash_direction = (hunter.player.global_position - hunter.global_position).normalized()
	else:
		dash_direction = Vector2.RIGHT # Fallback
		
	if hunter.dash_sound and hunter.dash_sound.stream:
		hunter.dash_sound.pitch_scale = randf_range(0.9, 1.1)
		hunter.dash_sound.play()
	
	hunter.velocity = dash_direction * hunter.dash_speed

func physics_update(_delta) -> void:
	hunter.velocity = dash_direction * hunter.dash_speed
	hunter.move_and_slide()
	
	# Sale del estado cuando se aleja suficiente del jugador tras el impacto o al pasarlo de largo
	if hunter.player and hunter.global_position.distance_to(hunter.player.global_position) > DASH_EXIT_DISTANCE:
		transitioned.emit(self, "Retreat")
