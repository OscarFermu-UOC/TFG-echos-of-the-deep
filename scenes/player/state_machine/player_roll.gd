# Estado que ejecuta la esquiva del jugador, gestionando su duración, cooldown e invulnerabilidad.
extends State
class_name PlayerRoll

@export var player: Player

func enter() -> void:
	player.can_roll = false
	player.play_animation("Roll")
	
	if player.roll_sound and player.roll_sound.stream:
		player.roll_sound.pitch_scale = randf_range(0.9, 1.1)
		player.roll_sound.play()
	
	EventBus.noise_made.emit()
	
	# Desactivamos colisiones durante el roll para que el jugador sea invulnerable
	if player.hurtbox_col:
		player.hurtbox_col.set_deferred("disabled", true)
	player.set_collision_mask_value(4, false)
	
	await get_tree().create_timer(player.roll_duration).timeout
	transitioned.emit(self, "Move")

func physics_update(_delta: float) -> void:
	player.velocity = player.roll_vector * player.roll_speed
	player.move_and_slide()

func exit() -> void:
	# Restauramos las colisiones al salir del estado
	if player.hurtbox_col:
		player.hurtbox_col.set_deferred("disabled", false)
	player.set_collision_mask_value(4, true)
	
	player.velocity = Vector2.ZERO
	_start_cooldown()
	
func _start_cooldown() -> void:
	await get_tree().create_timer(player.roll_cooldown).timeout
	player.can_roll = true
