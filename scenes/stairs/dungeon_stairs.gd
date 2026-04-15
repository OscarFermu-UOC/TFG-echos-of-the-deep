# Escaleras del dungeon: permiten bajar o subir de nivel, con sistema de bloqueo por llave.
extends Node2D
class_name DungeonStairs

enum Type { DOWN, UP }

# ==========================================================
# CONSTANTES
# ==========================================================
const REVEAL_DURATION: float = 0.5
const PROMPT_POP_DURATION: float = 0.2
const UNLOCK_FLASH_DURATION: float = 0.2
const UNLOCK_FLASH_COLOR: Color = Color(2.0, 2.0, 2.0) # Flash blanco brillante al desbloquearse
const LOCKED_SHAKE_OFFSET: float = 5.0
const LOCKED_SHAKE_STEP: float = 0.05

const LABEL_DESCEND: String = "[F] DESCEND"
const LABEL_ASCEND: String = "[F] ASCEND"
const LABEL_LOCKED: String = "LOCKED"
const LABEL_LOCKED_HINT: String = "LOCKED (Find Key)"

# ==========================================================
# EXPORTS
# ==========================================================
@export var type: Type = Type.DOWN

@export_group("Visuals")
@export var texture_down: Texture2D
@export var texture_up: Texture2D

# ==========================================================
# REFERENIAS
# ==========================================================
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _ui_prompt: Control = $UI_Prompt
@onready var _prompt_label: Label = $UI_Prompt/Label
@onready var _reveal_sound: AudioStreamPlayer2D = $Audio/RevealSound
@onready var _use_sound: AudioStreamPlayer2D = $Audio/UseSound
@onready var _locked_sound: AudioStreamPlayer2D = $Audio/LockedSound

# ==========================================================
# ESTADO
# ==========================================================
var artifact_collected: bool = false
var is_revealed: bool = false
var can_interact: bool = false
var is_locked: bool = true
var _target_scale: Vector2

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	_target_scale = _sprite.scale
	_sprite.scale = Vector2.ZERO
	_ui_prompt.hide()
	set_process_unhandled_input(false)

	if type == Type.DOWN:
		_sprite.texture = texture_down
		add_to_group("StairsDown")
		_update_lock_state()
		EventBus.key_collected.connect(_on_key_collected)
	else:
		_sprite.texture = texture_up
		add_to_group("StairsUp")
		is_locked = false # Las escaleras de subida nunca están bloqueadas

# ==========================================================
# ESTADO LOCK
# ==========================================================
func _update_lock_state() -> void:
	if type == Type.UP:
		return
	is_locked = not GlobalData.has_dungeon_key
	if can_interact:
		_prompt_label.text = LABEL_DESCEND if not is_locked else LABEL_LOCKED_HINT

func _on_key_collected() -> void:
	_update_lock_state()
	if not is_revealed:
		return
	
	# Flash para indicar visualmente que las escaleras se han desbloqueado
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate", UNLOCK_FLASH_COLOR, UNLOCK_FLASH_DURATION)
	tween.tween_property(_sprite, "modulate", Color.WHITE, UNLOCK_FLASH_DURATION)

func _on_artifact_picked_up(_artifact: ArtifactData) -> void:
	artifact_collected = true

# ==========================================================
# ZONA DE VISIBILIDAD
# ==========================================================
func _on_visibility_area_body_entered(body: Node2D) -> void:
	if is_revealed or not body.is_in_group("Player"):
		return
	_reveal()

func _reveal() -> void:
	is_revealed = true
	_sprite.visible = true
	
	if _reveal_sound and _reveal_sound.stream:
		_reveal_sound.play()
	
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "scale", _target_scale, REVEAL_DURATION).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# ==========================================================
# ZONA DE INTERACCIÓN
# ==========================================================
func _on_interaction_area_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	can_interact = true

	if is_locked:
		_prompt_label.text = LABEL_LOCKED
		_prompt_label.modulate = Color.RED
	else:
		_prompt_label.text = LABEL_DESCEND if type == Type.DOWN else LABEL_ASCEND
		_prompt_label.modulate = Color.WHITE

	_ui_prompt.scale = Vector2.ZERO
	_ui_prompt.show()
	set_process_unhandled_input(true)
	
	var tween: Tween = create_tween()
	tween.tween_property(_ui_prompt, "scale", Vector2.ONE, PROMPT_POP_DURATION).set_trans(Tween.TRANS_BACK)

func _on_interaction_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	can_interact = false
	_ui_prompt.hide()
	set_process_unhandled_input(false)

# ==========================================================
# INPUT
# ==========================================================
func _unhandled_input(event: InputEvent) -> void:
	if not can_interact or not event.is_action_pressed("interact"):
		return
	if is_locked:
		_play_locked_feedback()
	else:
		_use_stairs()

func _play_locked_feedback() -> void:
	if _locked_sound and _locked_sound.stream:
		_locked_sound.play()
		
	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "position:x",  LOCKED_SHAKE_OFFSET, LOCKED_SHAKE_STEP)
	tween.tween_property(_sprite, "position:x", -LOCKED_SHAKE_OFFSET, LOCKED_SHAKE_STEP)
	tween.tween_property(_sprite, "position:x",  0.0, LOCKED_SHAKE_STEP)

func _use_stairs() -> void:
	if _use_sound and _use_sound.stream:
		_use_sound.reparent(get_parent())
		_use_sound.play()
	
	set_process_unhandled_input(false)
	can_interact = false
	_ui_prompt.hide()
	EventBus.stairs_used.emit(type)
