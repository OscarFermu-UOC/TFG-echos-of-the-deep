# Estado de retirada del Hunter: huye a un punto aleatorio lejano y espera antes de volver a orbitar.
extends State
class_name HunterRetreat

const RETREAT_SCATTER_DISTANCE: float = 1000.0 # Distancia del punto de huida respecto al jugador
const RETREAT_VELOCITY_LERP: float = 0.05

@export var hunter: Hunter
var retreat_target: Vector2
var timer: float = 0.0

func enter() -> void:
	hunter.hitbox.set_deferred("monitoring", false)
	hunter.modulate.a = 0.3 # Más transparente durante la huida
	
	if hunter.retreat_sound and hunter.retreat_sound.stream:
		hunter.retreat_sound.pitch_scale = randf_range(0.9, 1.1)
		hunter.retreat_sound.play()
	
	timer = hunter.retreat_duration
	
	# El punto de huida se elige en una dirección aleatoria alejada del jugador
	if hunter.player:
		var random_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		retreat_target = hunter.player.global_position + random_dir * RETREAT_SCATTER_DISTANCE

func physics_update(delta) -> void:
	timer -= delta
	if timer <= 0:
		transitioned.emit(self, "Hover")
		return
		
	var dir: Vector2 = hunter.global_position.direction_to(retreat_target)
	hunter.velocity = hunter.velocity.lerp(dir * hunter.retreat_speed, RETREAT_VELOCITY_LERP)
	hunter.move_and_slide()
