# Nodo base del enemigo: inicializa sus stats, gestiona movimiento, animaciones y combate.
extends CharacterBody2D
class_name Enemy

@export var stats: EnemyStats

# ==========================================================
# EXPORTS
# ==========================================================
@export_group("Procedural Animation")
@export var bob_freq : float = 12.0
@export var bob_amp : float = 8.0
@export var squash_amount : float = 0.05
@export var tilt_angle : float = 8.0
@export var attack_lunge_amount : float = 10.0

# ==========================================================
# CONSTANTES
# ==========================================================
const VELOCITY_MOVE_THRESHOLD: float = 5.0
const SHAKE_OFFSET: float = 5.0
const SHAKE_STEP_DURATION: float = 0.05
const DEATH_SQUASH_DURATION: float = 0.2
const DEATH_FADE_DURATION: float = 0.5
const DEATH_FREE_DELAY: float = 0.5
 
const NAV_PATH_DISTANCE: float = 10.0
const NAV_TARGET_DISTANCE: float = 10.0

const STEP_INTERVAL: float = 0.4
 
# Timings y magnitudes de la animación de ataque
const ATTACK_WINDUP_DURATION: float = 0.2
const ATTACK_STRIKE_DURATION: float = 0.1
const ATTACK_RECOVER_DURATION: float = 0.4
const ATTACK_WINDUP_ROTATION: float = 0.2
const ATTACK_STRIKE_ROTATION: float = 0.3

# ==========================================================
# VARIABLES DEL ENEMIGO
# ==========================================================
var current_health: int
var damage: int
var move_speed: float
var attack_range: float
var detection_range: float
var stop_distance: float
var min_safe_distance: float
var wander_radius: float

# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var audio_idle: AudioStreamPlayer2D = $Audio/IdleSound
@onready var audio_step: AudioStreamPlayer2D = $Audio/StepSound
@onready var audio_attack: AudioStreamPlayer2D = $Audio/AttackSound
@onready var audio_hurt: AudioStreamPlayer2D = $Audio/HurtSound
@onready var audio_death: AudioStreamPlayer2D = $Audio/DeathSound
@onready var audio_alert: AudioStreamPlayer2D = $Audio/AlertSound
@onready var audio_stun: AudioStreamPlayer2D = $Audio/StunSound
@onready var visual_pivot: Node2D = $VisualPivot
@onready var sprite: Sprite2D = $VisualPivot/Sprite2D
@onready var health_bar: ProgressBar = $HealthBarRoot/HealthBar
@onready var state_machine: StateMachine = $"State Machine"

# ==========================================================
# VARIABLES DE LÓGICA
# ==========================================================
var player: Node2D
var facing_direction: Vector2 = Vector2.DOWN

var anim_time : float = 0.0
var is_attacking_anim : bool = false # Evita superponer la animación de ataque con otras
var step_timer: float = 0.0

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	if not stats:
		push_error("ERROR: El enemigo no tiene EnemyStats asignado.")
		set_physics_process(false) 
		return
		
	_initialize_enemy()
	add_to_group("Enemy")
	
	# Esperamos un frame de física para que la navegación esté lista
	await get_tree().physics_frame
	player = get_tree().get_first_node_in_group("Player")
	
	# Configurar navegación
	nav_agent.path_desired_distance = NAV_PATH_DISTANCE
	nav_agent.target_desired_distance = NAV_TARGET_DISTANCE
	nav_agent.avoidance_enabled = true
	
	# Configurar barra de vida
	health_bar.max_value = stats.max_health
	health_bar.value = current_health
	health_bar.visible = false

func _physics_process(delta) -> void:
	if not is_attacking_anim:
		_apply_procedural_animation(delta)

	if velocity.length() > 0:
		facing_direction = velocity.normalized()
		update_blend_position(facing_direction)
		
	_handle_footsteps(delta)
		
# ==========================================================
# INICIALIZACIÓN
# ==========================================================	
func _initialize_enemy() -> void:
	sprite.texture = stats.texture
	current_health = stats.max_health
	damage = stats.damage
	move_speed = stats.move_speed
	attack_range = stats.attack_range
	detection_range = stats.detection_range
	stop_distance = stats.stop_distance
	min_safe_distance = stats.min_safe_distance
	wander_radius = stats.wander_radius

# ==========================================================
# SONIDO MOVIMIENTO
# ==========================================================
func _handle_footsteps(delta: float) -> void:
	step_timer -= delta
	if step_timer <= 0 and velocity.length() > 10.0:
		if audio_step and audio_step.stream:
			# Pequeña variación de pitch para que no suene robótico
			audio_step.pitch_scale = randf_range(0.9, 1.1)
			audio_step.play()
		step_timer = STEP_INTERVAL
	
# ==========================================================
# API PARA LOS ESTADOS
# ==========================================================
func move_towards_target(target_pos: Vector2) -> void:
	nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		return

	var next_pos = nav_agent.get_next_path_position()
	var dir = global_position.direction_to(next_pos)
	
	velocity = dir * move_speed
	move_and_slide()

func stop_movement() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func perform_attack() -> void:
	pass # Implementado por cada tipo de enemigo concreto

# ==========================================================
# SISTEMA DE ANIMACIÓN
# ==========================================================
func _apply_procedural_animation(delta: float) -> void:
	var is_moving: bool = velocity.length() > VELOCITY_MOVE_THRESHOLD
 
	# Bob
	if is_moving:
		anim_time += delta * bob_freq
	else:
		anim_time = lerp(anim_time, round(anim_time / PI) * PI, 10.0 * delta)
 
	var bob_sine: float = sin(anim_time)
	var target_y: float = -absf(bob_sine) * bob_amp if is_moving else 0.0
	visual_pivot.position.y = lerpf(visual_pivot.position.y, target_y, 15.0 * delta)
 
	# Squash and Stretch
	var target_scale := Vector2.ONE
	if is_moving:
		var deformation: float = bob_sine * squash_amount
		target_scale = Vector2(1.0 - deformation, 1.0 + deformation)
	visual_pivot.scale = visual_pivot.scale.lerp(target_scale, 15.0 * delta)
 
	# Tilt (inclinación en la dirección del movimiento)
	var target_rotation: float = 0.0
	if is_moving:
		var rotation_strength: float = clampf(velocity.x / move_speed, -1.0, 1.0)
		target_rotation = deg_to_rad(rotation_strength * tilt_angle)
	visual_pivot.rotation = lerp_angle(visual_pivot.rotation, target_rotation, 10.0 * delta)
 
# Llamada por los estados FSM
func play_animation(anim_name: String) -> void:
	match anim_name:
		"Idle", "Walk":
			pass # Gestionadas en _physics_process
		"Attack":
			_animate_attack()
		"Death":
			_animate_death()
 
func update_blend_position(dir: Vector2) -> void:
	if dir.x != 0.0:
		sprite.flip_h = dir.x > 0.0
 
func _animate_attack() -> void:
	if is_attacking_anim:
		return
	is_attacking_anim = true
 
	var dir_sign: float = -1.0 if sprite.flip_h else 1.0
	var tween: Tween = create_tween()
 
	# Windup: se echa hacia atrás y se aplasta
	tween.tween_property(visual_pivot, "rotation", -ATTACK_WINDUP_ROTATION * dir_sign, ATTACK_WINDUP_DURATION).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(visual_pivot, "scale", Vector2(1.1, 0.9), ATTACK_WINDUP_DURATION)
 
	# Strike: lanza hacia delante y se estira
	tween.chain().tween_property(visual_pivot, "rotation", ATTACK_STRIKE_ROTATION * dir_sign, ATTACK_STRIKE_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visual_pivot, "scale", Vector2(0.8, 1.2), ATTACK_STRIKE_DURATION)
 
	# El daño se aplica en el momento exacto del impacto visual
	tween.tween_callback(perform_attack)
 
	# Recover: vuelve a la posición neutral
	tween.chain().tween_property(visual_pivot, "rotation", 0.0, ATTACK_RECOVER_DURATION).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visual_pivot, "scale", Vector2.ONE, ATTACK_RECOVER_DURATION)
 
	await tween.finished
	is_attacking_anim = false
 
func _animate_death() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(visual_pivot, "scale", Vector2(1.5, 0.1), DEATH_SQUASH_DURATION).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, DEATH_FADE_DURATION)
	await tween.finished

# ==========================================================
# DAÑO Y SALUD
# ==========================================================
func apply_stun(duration: float) -> void:
	var stun_node = state_machine.get_node_or_null("Stunned")
	
	if not stun_node:
		return
	
	stun_node.stun_duration = duration
	state_machine.on_child_transition(state_machine.current_state, "Stunned")
		
func take_damage(amount: int) -> void:
	current_health -= amount
	
	health_bar.value = current_health
	health_bar.visible = true
	
	EventBus.damage_received.emit(amount, position, false)
	
	if audio_hurt and audio_hurt.stream:
		audio_hurt.pitch_scale = randf_range(0.95, 1.05)
		audio_hurt.play()
	
	# Flash blanco al recibir daño
	var flash_tween: Tween = create_tween()
	sprite.modulate = Color.WHITE
	flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
 
	# Sacudida horizontal
	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(visual_pivot, "position:x", SHAKE_OFFSET, SHAKE_STEP_DURATION)
	shake_tween.chain().tween_property(visual_pivot, "position:x", -SHAKE_OFFSET, SHAKE_STEP_DURATION)
	shake_tween.chain().tween_property(visual_pivot, "position:x",  0.0, SHAKE_STEP_DURATION)
		
	if current_health <= 0:
		die()

func die() -> void:
	set_physics_process(false) 
	stop_movement()
	
	if audio_death and audio_death.stream:
		audio_death.reparent(get_parent())
		audio_death.play()
		await audio_death.finished
		audio_death.queue_free()
	
	EventBus.enemy_died.emit()
	
	# Esperamos a que termine la animación antes de liberar el nodo
	_animate_death()
	await get_tree().create_timer(DEATH_FREE_DELAY).timeout
	queue_free()
