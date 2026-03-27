# Estado de persecución: el enemigo sigue al jugador y ataca si está en rango.
extends State
class_name EnemyChase

const PATH_UPDATE_INTERVAL: float = 0.2 # Segundos entre recálculos de ruta

@export var enemy: Enemy
var path_timer: float = 0.0

func enter() -> void:
	enemy.play_animation("Walk")
	
	if enemy.audio_alert and enemy.audio_alert.stream:
		enemy.audio_alert.play()

func physics_update(delta) -> void:
	if not enemy.player:
		transitioned.emit(self, "Idle")
		return

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	
	# Pierde el aggro si el jugador está lejos y no hay línea de visión
	if dist > enemy.detection_range and not _has_line_of_sight():
		transitioned.emit(self, "Idle")
		return
		
	if dist <= enemy.attack_range and _has_line_of_sight():
		transitioned.emit(self, "Attack")
		return

	# Recalculamos la ruta periódicamente para no sobrecargar el pathfinding
	path_timer -= delta
	
	if path_timer <= 0.0:
		path_timer = PATH_UPDATE_INTERVAL
		
	enemy.move_towards_target(enemy.player.global_position)

func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		enemy.global_position, enemy.player.global_position
	)
	query.exclude = [enemy]
	var result: Dictionary = enemy.get_world_2d().direct_space_state.intersect_ray(query)
	return result and result.collider == enemy.player
