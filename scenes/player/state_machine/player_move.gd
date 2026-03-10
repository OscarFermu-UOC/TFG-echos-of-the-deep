# Estado que gestiona el movimiento, apuntado, disparo y transiciones del jugador.
extends State
class_name PlayerMove

@export var player: Player

func Enter():
	player.play_animation("Idle")
	
func Physics_Update(delta: float):
	if not player: return
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# La dirección de mira se calcula desde el jugador hacia el ratón
	var mouse_pos = player.get_global_mouse_position()
	player.look_vector = (mouse_pos - player.global_position).normalized()
	
	# Velocidad según si el jugador está corriendo o andando
	var target_speed = 0.0
	var is_running = Input.is_action_pressed("run")
	if input_vector != Vector2.ZERO:
		target_speed = (player.run_speed if is_running else player.walk_speed) * player.temp_speed_mult
		player.roll_vector = input_vector
		player.velocity = player.velocity.move_toward(input_vector * target_speed, player.acceleration * delta)
	else:
		player.velocity = player.velocity.move_toward(Vector2.ZERO, player.friction * delta)
	
	# Emite ruido cada vez que el jugador recorre una distancia determinada corriendo
	if is_running and player.velocity.length() > 10:
		player.distance_traveled += player.velocity.length() * delta
		if player.distance_traveled >= player.noise_distance_threshold:
			player.distance_traveled = 0.0
			EventBus.noise_made.emit()
	
	# Actualiza la animación según velocidad y si está corriendo o andando
	player.update_blend_space(player.look_vector)
	if player.velocity.length() > 5:
		player.play_animation("Run" if is_running else "Walk")
	else:
		player.play_animation("Idle")
		
	if Input.is_action_pressed("shoot"):
		player.weapon_system.shoot(player.look_vector)
		player.velocity *= 0.8 # Ralentizar al disparar para dar sensación de peso
		
	player.move_and_slide()
	
	if Input.is_action_just_pressed("roll") and player.can_roll and input_vector != Vector2.ZERO:
		Transitioned.emit(self, "Roll")
