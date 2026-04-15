# Artefacto del nivel: se revela al acercarse, se recoge con interacción y emite una señal al hacerlo.
extends Node2D
class_name CompassTarget

# ==========================================================
# CONSTANTES
# ==========================================================
const REVEAL_DURATION: float = 0.5
const PICKUP_SQUASH_DURATION: float = 0.2
const PICKUP_FADE_DURATION: float = 0.2
const PICKUP_SCALE_TARGET: Vector2 = Vector2(2.0, 0.0) # Aplasta el sprite al recogerlo
const FLOAT_OFFSET: float = 5.0
const FLOAT_DURATION: float = 1.5
const PROMPT_POP_DURATION: float = 0.2

# ==========================================================
# EXPORTS
# ==========================================================
@export var artifact_database: ArtifactDatabase

# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _ui_prompt: Control = $UI_Prompt
@onready var _reveal_sound: AudioStreamPlayer2D = $Audio/RevealSound
@onready var _pickup_sound: AudioStreamPlayer2D = $Audio/PickupSound

# ==========================================================
# ESTADO
# ==========================================================
var current_artifact_data: ArtifactData
var can_pickup: bool = false
var is_revealed: bool = false
var _target_scale: Vector2

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	_initialize_artifact()

	_target_scale = _sprite.scale
	_sprite.scale = Vector2.ZERO
	_sprite.hide()
	_ui_prompt.hide()
	set_process_unhandled_input(false)

	add_to_group("Artifact")
	EventBus.artifact_selected.emit()
	_play_float_anim()

# ==========================================================
# INICIALIZACIÓN
# ==========================================================
func _initialize_artifact() -> void:
	if not artifact_database:
		push_error("Artifact: no ArtifactDatabase assigned in the inspector.")
		return

	current_artifact_data = artifact_database.get_random_artifact_for_level(GlobalData.current_cycle)

	if current_artifact_data:
		_sprite.texture = current_artifact_data.icon
	else:
		push_error("Artifact: could not generate an artifact for cycle %d." % GlobalData.current_cycle)

# ==========================================================
# ZONA DE VISIBILIDAD
# ==========================================================
func _on_visibility_area_body_entered(body: Node2D) -> void:
	if is_revealed or not body.is_in_group("Player"):
		return
	_reveal_artifact()

func _reveal_artifact() -> void:
	is_revealed = true
	_sprite.show()
	_sprite.scale = Vector2.ZERO
	
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", _target_scale, REVEAL_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	if _reveal_sound and _reveal_sound.stream:
		_reveal_sound.play()

# ==========================================================
# ZONA DE INTERACCIÓN
# ==========================================================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player") or self != GlobalData.target:
		return
	can_pickup = true
	_ui_prompt.scale = Vector2.ZERO
	_ui_prompt.show()
	set_process_unhandled_input(true)
	
	var tween: Tween = create_tween()
	tween.tween_property(_ui_prompt, "scale", Vector2.ONE, PROMPT_POP_DURATION).set_trans(Tween.TRANS_BACK)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player") or self != GlobalData.target:
		return
	can_pickup = false
	_ui_prompt.hide()
	set_process_unhandled_input(false)

# ==========================================================
# INPUT
# ==========================================================
func _unhandled_input(event: InputEvent) -> void:
	if can_pickup and event.is_action_pressed("interact"):
		_pick_up()

func _pick_up() -> void:
	if not current_artifact_data:
		return

	EventBus.artifact_picked_up.emit(current_artifact_data)
	EventBus.noise_made.emit(5)

	set_process_unhandled_input(false)
	_ui_prompt.hide()
	
	if _pickup_sound and _pickup_sound.stream:
		_pickup_sound.reparent(get_parent())
		_pickup_sound.play()

	# Aplasta y desvanece el sprite antes de destruir el nodo
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", PICKUP_SCALE_TARGET, PICKUP_SQUASH_DURATION).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property(_sprite, "modulate:a", 0.0, PICKUP_FADE_DURATION)
	tween.tween_callback(queue_free)

# ==========================================================
# EFECTOS VISUALES
# ==========================================================
func _play_float_anim() -> void:
	# Animación de flotación en bucle infinito
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_sprite, "position:y", -FLOAT_OFFSET, FLOAT_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y",  FLOAT_OFFSET, FLOAT_DURATION).set_trans(Tween.TRANS_SINE)
