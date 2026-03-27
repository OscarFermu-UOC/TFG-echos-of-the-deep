# Boss: orbita alrededor del jugador y lanza embestidas
extends CharacterBody2D
class_name Hunter

# ==========================================================
# EXPORTS
# ==========================================================
@export_group("Stats")
@export var hover_speed: float = 150.0
@export var dash_speed: float = 300.0
@export var retreat_speed: float = 150.0
@export var damage_percent: float = 0.5 # Daño como fracción de la salud máxima del jugador

@export_group("Timers")
@export var hover_duration: float = 4.0
@export var telegraph_duration: float = 1.0
@export var retreat_duration: float = 3.0

# ==========================================================
# CONSTANTES
# ==========================================================
const DAMAGE_SCALE_HIT_DURATION: float = 0.1 # Duración del feedback visual al recibir daño

# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var state_machine: StateMachine = $"State Machine"
@onready var telegraph_sound: AudioStreamPlayer2D = $Audio/TelegraphSound
@onready var dash_sound: AudioStreamPlayer2D = $Audio/DashSound
@onready var hurt_sound: AudioStreamPlayer2D = $Audio/HurtSound
@onready var retreat_sound: AudioStreamPlayer2D = $Audio/RetreatSound

# ==========================================================
# VARIABLES DE LÓGICA
# ==========================================================
var player: Player

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Hunter")
	
	hitbox.monitoring = false # La hitbox solo se activa durante el dash

# ==========================================================
# API PÚBLICA
# ==========================================================
func face_player() -> void:
	if not player: return
	sprite.flip_h = player.global_position.x < global_position.x

# ==========================================================
# DAÑO Y SALUD
# ==========================================================
func take_damage(_amount: int) -> void:
	if hurt_sound and hurt_sound.stream:
		hurt_sound.pitch_scale = randf_range(0.9, 1.1)
		hurt_sound.play()
		
	# Escala brevemente el sprite para indicar que recibió un golpe
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), DAMAGE_SCALE_HIT_DURATION)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), DAMAGE_SCALE_HIT_DURATION)
	
	# Interrumpimos el estado actual y forzamos la retirada
	state_machine.on_child_transition(state_machine.current_state, "Retreat")

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.owner != player and area.get_parent() != player:
		return
		
	if not player.has_method("take_damage"):
		return
		
	# El daño se calcula como porcentaje de la salud máxima del jugador
	var dmg = ceil(player.max_health * damage_percent)
	player.take_damage(dmg)
	state_machine.on_child_transition(state_machine.current_state, "Retreat")
