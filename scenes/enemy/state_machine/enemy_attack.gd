# Estado de ataque del enemigo
extends State
class_name EnemyAttack

const ATTACK_COMMIT_DURATION: float = 0.4 # Duración mínima del ataque antes de poder transicionar

@export var enemy: Enemy

var is_attacking: bool = false

func enter() -> void:
	enemy.stop_movement()
	
	if enemy.player:
		var dir = (enemy.player.global_position - enemy.global_position).normalized()
		enemy.update_blend_position(dir)
	
	enemy.play_animation("Attack")
	is_attacking = true
	
	await get_tree().create_timer(ATTACK_COMMIT_DURATION).timeout
	is_attacking = false
	
	_decide_next_state()

func _decide_next_state() -> void:
	if not enemy.player:
		transitioned.emit(self, "Idle")
		return

	var dist: float = enemy.global_position.distance_to(enemy.player.global_position)
	
	# Si es un enemigo a distancia y el jugador está demasiado cerca, retroceder
	if enemy.min_safe_distance > 0.0 and dist < enemy.min_safe_distance:
		transitioned.emit(self, "Retreat")
		return

	if dist <= enemy.attack_range:
		transitioned.emit(self, "Attack") # Sigue en rango, repetir ataque
	else:
		transitioned.emit(self, "Chase")  # Se alejó, perseguir
