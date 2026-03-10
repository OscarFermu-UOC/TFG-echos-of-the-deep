# Estado que ejecuta la esquiva del jugador, gestionando su duración, cooldown e invulnerabilidad.
extends State
class_name PlayerRoll

@export var player: Player

func Enter():
	player.can_roll = false
	player.play_animation("Roll")
	player.roll_sound.play()
	EventBus.noise_made.emit()
	
	# Desactivamos colisiones durante el roll para que el jugador sea invulnerable
	if player.hurtbox_col:
		player.hurtbox_col.set_deferred("disabled", true)
	player.set_collision_mask_value(4, false)
	
	await get_tree().create_timer(player.roll_duration).timeout
	Transitioned.emit(self, "Move")

func Physics_Update(_delta: float):
	player.velocity = player.roll_vector * player.roll_speed
	player.move_and_slide()

func Exit():
	# Restauramos las colisiones al salir del estado
	if player.hurtbox_col:
		player.hurtbox_col.set_deferred("disabled", false)
	player.set_collision_mask_value(4, true)
	
	player.velocity = Vector2.ZERO
	_start_cooldown()
	
func _start_cooldown():
	await get_tree().create_timer(player.roll_cooldown).timeout
	player.can_roll = true
