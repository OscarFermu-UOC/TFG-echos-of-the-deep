# Estado de retirada: el enemigo huye del jugador hasta alcanzar una distancia segura.
extends State
class_name EnemyRetreat

const SAFE_DISTANCE: float = 1.2   # Multiplicador sobre min_safe_distance para dejar margen
const FLEE_LOOK_AHEAD: float = 100.0 # Distancia del punto de huida

@export var enemy: Enemy

func enter() -> void:
	enemy.play_animation("Walk")

func physics_update(_delta) -> void:
	if not enemy.player:
		transitioned.emit(self, "Idle")
		return

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	
	if dist > enemy.min_safe_distance * SAFE_DISTANCE:
		transitioned.emit(self, "Chase")
		return

	# Se mueve en dirección opuesta al jugador
	var dir_away: Vector2 = (enemy.global_position - enemy.player.global_position).normalized()
	enemy.move_towards_target(enemy.global_position + dir_away * FLEE_LOOK_AHEAD)
