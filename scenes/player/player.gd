# Nodo principal del jugador: inicializa sus stats, gestiona su salud y coordina animaciones.
extends CharacterBody2D
class_name Player

@export var stats: CharacterClass

# ==========================================================
# EXPORTS
# ==========================================================
@export_group("Procedural Animation")
@export var bob_freq_walk : float = 15.0
@export var bob_freq_run : float = 25.0
@export var bob_amp_walk : float = 10.0
@export var bob_amp_run : float = 5.0
@export var squash_amount : float = 0.1
@export var tilt_angle : float = 5.0

# ==========================================================
# CONSTANTES
# ==========================================================
const VELOCITY_IDLE_THRESHOLD: float = 10.0
const REVIVE_HEALTH: int = 40
const REVIVE_INVULNERABILITY_DURATION: float = 2.0

const STEP_WALK_INTERVAL: float = 0.5
const STEP_RUN_INTERVAL: float = 0.3

# ==========================================================
# STATE
# ==========================================================
var current_health: int
var max_health: int
var walk_speed: float
var run_speed: float
var acceleration: float
var friction: float
var roll_speed: float
var roll_duration: float
var roll_cooldown: float
var noise_distance_threshold: float

# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var hurtbox_col: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var weapon_system: WeaponSystem = $WeaponHolder
@onready var state_machine: StateMachine = $StateMachine
@onready var visual_pivot: Node2D = $VisualPivot
@onready var sprite: Sprite2D = $VisualPivot/Sprite2D

@onready var step_sound: AudioStreamPlayer2D = $Audio/StepSound
@onready var roll_sound: AudioStreamPlayer2D = $Audio/RollSound 
@onready var hurt_sound: AudioStreamPlayer2D = $Audio/HurtSound
@onready var death_sound: AudioStreamPlayer2D = $Audio/DeathSound
@onready var revive_sound: AudioStreamPlayer2D = $Audio/ReviveSound

# ==========================================================
# VARIABLES DE LÓGICA
# ==========================================================
var input_vector: Vector2 = Vector2.ZERO 
var look_vector: Vector2 = Vector2.DOWN 
var roll_vector: Vector2 = Vector2.DOWN 
var can_roll: bool = true
var temp_speed_mult: float = 1.0

var distance_traveled: float = 0.0
var has_revive: bool = false

var anim_time : float = 0.0
var is_rolling_anim : bool = false # Evita superponer la animación de roll con otras

var step_timer: float = 0.0

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	add_to_group("Player")
	
	# TODO: Load stats from save
	
	if not stats:
		push_error("ERROR: El player no tiene CharacterClass asignado.")
		set_physics_process(false)
		return
	
	_initialize_character()
	
func _physics_process(delta: float) -> void:
	if not is_rolling_anim:
		_apply_procedural_animation(delta)
		_handle_footsteps(delta)
		
# ==========================================================
# INICIALIZACIÓN
# ==========================================================
func _initialize_character() -> void:
	sprite.texture = stats.portrait
	current_health = stats.max_health
	max_health = stats.max_health
	walk_speed = stats.walk_speed
	run_speed = stats.run_speed
	acceleration = stats.acceleration
	friction = stats.friction
	roll_speed = stats.roll_speed
	roll_duration = stats.roll_duration
	roll_cooldown = stats.roll_cooldown
	noise_distance_threshold = stats.noise_distance_threshold
	
	# TODO: Aplicar meta-progresion
	# TODO: Aplicar reliquias
	
	if stats.starting_weapon:
		# TODO: Aplicar mejoras del arma
		weapon_system.equip_weapon(stats.starting_weapon)

	EventBus.health_changed.emit(current_health, max_health)
	
# ==========================================================
# SONIDO MOVIMIENTO
# ==========================================================
func _handle_footsteps(delta: float) -> void:
	var speed: float = velocity.length()

	if speed <= VELOCITY_IDLE_THRESHOLD:
		step_timer = 0.0  
		return

	var is_running: bool = speed > walk_speed + VELOCITY_IDLE_THRESHOLD
	var interval: float = STEP_RUN_INTERVAL if is_running else STEP_WALK_INTERVAL

	step_timer -= delta
	if step_timer <= 0.0:
		step_timer = interval
		if step_sound and step_sound.stream:
			step_sound.pitch_scale = randf_range(0.9, 1.1)
			step_sound.play()

# ==========================================================
# SISTEMA DE ANIMACIÓN
# ==========================================================
func _apply_procedural_animation(delta: float) -> void:
	var speed: float = velocity.length()
	var is_moving: bool = speed > VELOCITY_IDLE_THRESHOLD
	var is_running: bool = speed > walk_speed + VELOCITY_IDLE_THRESHOLD
	
	var current_freq: float = bob_freq_run if is_running else bob_freq_walk
	var current_amp: float = bob_amp_run  if is_running else bob_amp_walk
	
	# Bob
	if is_moving:
		anim_time += delta * current_freq
	else:
		# Si está en reposo se suaviza el anim_time al múltiplo de PI
		#más cercano para que el sprite no se quede a mitad del ciclo
		anim_time = lerp(anim_time, round(anim_time / PI) * PI, 10 * delta)

	var bob_sine = sin(anim_time)
	var target_y = -abs(bob_sine) * current_amp if is_moving else 0.0
	visual_pivot.position.y = lerp(visual_pivot.position.y, target_y, 15 * delta)

	# Squash and Stretch
	var target_scale = Vector2.ONE
	if is_moving:
		var deformation = bob_sine * squash_amount
		target_scale = Vector2(1.0 - deformation, 1.0 + deformation)
	
	visual_pivot.scale = visual_pivot.scale.lerp(target_scale, 15 * delta)

	# Tilt (inclinación en la dirección del movimiento)
	var tilt_mult = 1.5 if is_running else 1.0
	var target_rotation = 0.0
	if is_moving:
		# Usamos velocity.x para inclinar hacia donde vamos
		var rotation_strength = clampf(velocity.x / walk_speed, -1.0, 1.0)
		target_rotation = deg_to_rad(rotation_strength * tilt_angle * tilt_mult)
	
	visual_pivot.rotation = lerp_angle(visual_pivot.rotation, target_rotation, 10 * delta)

# Llamado por los Estados (StateMachine)
func update_blend_space(dir: Vector2) -> void:
	if dir.x != 0:
		sprite.flip_h = dir.x > 0

# Llamado por los Estados (StateMachine)
func play_animation(anim_name: String) -> void:
	match anim_name:
		"Roll":
			_animate_roll()
		"Death":
			_animate_death()
		"Idle", "Walk", "Run":
			# Estas animaciones se gestionan automáticamente en _apply_procedural_animation
			pass

func _animate_roll() -> void:
	is_rolling_anim = true
	
	var tween = create_tween()
	tween.set_parallel(true) 
	
	# 1. Girar 360 grados (usando TAU)
	var rot_dir = 1 if velocity.x >= 0 else -1
	tween.tween_property(visual_pivot, "rotation", rot_dir * TAU, roll_duration).as_relative()
	
	# Aplastar en la primera mitad y recuperar en la segunda
	tween.tween_property(visual_pivot, "scale", Vector2(1.3, 0.7), roll_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(visual_pivot, "scale", Vector2(1.0, 1.0), roll_duration * 0.5)
	
	await tween.finished
	
	visual_pivot.rotation = 0 # Reset para evitar acumulación de rotación
	is_rolling_anim = false

func _animate_death() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(visual_pivot, "scale", Vector2(1.5, 0.1), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual_pivot, "modulate:a", 0.0, 0.5)

# ==========================================================
# DAÑO Y SALUD
# ==========================================================
func take_damage(amount: int) -> void:
	# Durante el roll el jugador es invulnerable
	if state_machine.current_state.name == "Roll":
		return

	current_health -= amount
	EventBus.health_changed.emit(current_health, max_health)
	EventBus.damage_received.emit(amount, position, true)
	
	if current_health <= 0:
		if has_revive:
			_trigger_revive()
		else:
			die()
		return
		
	if hurt_sound and hurt_sound.stream:
		hurt_sound.pitch_scale = randf_range(0.95, 1.05)
		hurt_sound.play()

	# Flash rojo al recibir daño
	var tween = create_tween()
	sprite.modulate = Color.RED
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func _trigger_revive() -> void:
	has_revive = false
	
	current_health = REVIVE_HEALTH
	EventBus.health_changed.emit(current_health, max_health)
	
	# Efecto visual en el player
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.GREEN, 0.2)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.5)
	
	if revive_sound and revive_sound.stream:
		revive_sound.play()
	
	# Invulnerabilidad temporal tras revivir
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", true)
		await get_tree().create_timer(REVIVE_INVULNERABILITY_DURATION).timeout
		hurtbox_col.set_deferred("disabled", false)

func die() -> void:
	if death_sound and death_sound.stream:
		death_sound.reparent(get_parent())
		death_sound.play()
	
	play_animation("Death")
	EventBus.player_died.emit()
	
	# Detenemos física del jugador y de la máquina de estados
	set_physics_process(false)
	state_machine.set_physics_process(false)
	state_machine.set_process(false)
