# Estado idle del enemigo: detecta al jugador y, si no lo ve, deambula por el escenario.
extends State
class_name EnemyIdle

const WANDER_ARRIVAL_THRESHOLD: float = 10.0 # Distancia para considerar que llegó al destino

@export var enemy: Enemy
@export var wander_time_min: float = 1.0
@export var wander_time_max: float = 3.0

var wander_timer: float = 0.0
var target_wander_pos: Vector2 = Vector2.ZERO
var is_wandering: bool = false

func enter() -> void:
	enemy.stop_movement()
	enemy.play_animation("Idle")
	
	is_wandering = false 
	
	_start_wait_timer()

func physics_update(delta) -> void:
	# Detección del jugador tiene prioridad sobre el vagabundeo
	if enemy.player:
		var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
		if dist < enemy.detection_range and _has_line_of_sight():
			transitioned.emit(self, "Chase")
			return

	if is_wandering:
		_update_wander()
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			_pick_new_wander_point()
			
func _update_wander() -> void:
	enemy.move_towards_target(target_wander_pos)
	enemy.play_animation("Walk")
 
	# Consideramos que llegó si está cerca del punto o el agente de navegación terminó
	var arrived: bool = enemy.global_position.distance_to(target_wander_pos) < WANDER_ARRIVAL_THRESHOLD or enemy.nav_agent.is_navigation_finished()
		
	if arrived:
		is_wandering = false
		enemy.stop_movement()
		enemy.play_animation("Idle")
		_start_wait_timer()

func _start_wait_timer() -> void:
	wander_timer = randf_range(wander_time_min, wander_time_max)

func _pick_new_wander_point() -> void:
	var random_dir := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var potential_pos: Vector2 = enemy.global_position + random_dir * enemy.wander_radius
	
	# Buscamos el punto navegable más cercano al destino aleatorio
	var map: RID = enemy.get_world_2d().get_navigation_map()
	
	target_wander_pos = NavigationServer2D.map_get_closest_point(map, potential_pos)
	is_wandering = true

func _has_line_of_sight() -> bool:
	var query := PhysicsRayQueryParameters2D.create(
		enemy.global_position, enemy.player.global_position
	)
	query.exclude = [enemy]
	var result: Dictionary = enemy.get_world_2d().direct_space_state.intersect_ray(query)
	return result and result.collider == enemy.player
