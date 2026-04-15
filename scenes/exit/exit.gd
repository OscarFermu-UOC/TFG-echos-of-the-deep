# Salida del nivel: se revela tras recoger el artefacto y permite completar la run al interactuar.
extends Node2D

# ==========================================================
# CONSTANTES
# ==========================================================
const REVEAL_DURATION: float = 0.6
const PROMPT_POP_DURATION: float = 0.2

# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var _sprite: Sprite2D = %Sprite2D
@onready var _ui_prompt: Control = $UI_Prompt
@onready var _reveal_sound: AudioStreamPlayer2D = $Audio/RevealSound
@onready var _exit_sound: AudioStreamPlayer2D = $Audio/ExitSound

# ==========================================================
# ESTADO
# ==========================================================
var artifact_collected: bool = false
var is_revealed: bool = false
var can_exit: bool = false
var _target_scale: Vector2
var _artifact: ArtifactData

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	_target_scale = _sprite.scale
	_sprite.scale = Vector2.ZERO
	_sprite.hide()
	_ui_prompt.hide()
	set_process_unhandled_input(false)

	add_to_group("Exit")
	EventBus.artifact_picked_up.connect(_on_artifact_picked_up)

	# Si estamos ascendiendo y el artefacto ya fue recogido antes de cargar esta escena,
	# restauramos el estado inmediatamente sin esperar a la señal
	if GlobalData.is_ascending and GlobalData.current_artifact_data:
		_on_artifact_picked_up(GlobalData.current_artifact_data)

# ==========================================================
# LOGICA
# ==========================================================
func _on_artifact_picked_up(artifact_data: ArtifactData) -> void:
	_artifact = artifact_data
	artifact_collected = true

# ==========================================================
# ZONA DE VISIBILIDAD
# ==========================================================
func _on_visibility_area_body_entered(body: Node2D) -> void:
	if not artifact_collected or is_revealed or not body.is_in_group("Player"):
		return
	_reveal_exit()

func _reveal_exit() -> void:
	is_revealed = true
	_sprite.show()
	
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", _target_scale, REVEAL_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
	if _reveal_sound and _reveal_sound.stream:
		_reveal_sound.play()

# ==========================================================
# ZONA DE INTERACCIÓN
# ==========================================================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not is_revealed or not body.is_in_group("Player"):
		return
		
	can_exit = true
	_ui_prompt.scale = Vector2.ZERO
	_ui_prompt.show()
	set_process_unhandled_input(true)
	
	var tween: Tween = create_tween()
	tween.tween_property(_ui_prompt, "scale", Vector2.ONE, PROMPT_POP_DURATION).set_trans(Tween.TRANS_BACK)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
		
	can_exit = false
	_ui_prompt.hide()
	set_process_unhandled_input(false)

# ==========================================================
# INPUT
# ==========================================================
func _unhandled_input(event: InputEvent) -> void:
	if can_exit and event.is_action_pressed("interact"):
		_escape()

func _escape() -> void:
	if _exit_sound and _exit_sound.stream:
		_exit_sound.reparent(get_parent())
		_exit_sound.play()
	
	set_process_unhandled_input(false)
	_ui_prompt.hide()
	
	EventBus.run_successful.emit(_artifact)
