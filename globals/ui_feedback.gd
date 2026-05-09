# Utilidad estática con animaciones de feedback reutilizables entre pantallas de tienda y mejoras.
class_name UIFeedback

const SHAKE_STEP: float = 0.05
const SHAKE_OFFSET: float = 2.0
const FLASH_DURATION: float = 0.05

const SOUND_CONFIRM: AudioStream = preload("res://assets/sounds/ui/confirm.wav")
const SOUND_CANT_AFFORD: AudioStream = preload("res://assets/sounds/ui/cant_afford.ogg")
const SOUND_UNLOCK: AudioStream = preload("res://assets/sounds/ui/unlock.ogg")
const SOUND_BACK: AudioStream = preload("res://assets/sounds/ui/back.wav")
const SOUND_PAUSE: AudioStream = preload("res://assets/sounds/ui/pause.wav")

# Shake horizontal + flash rojo para indicar que no se puede permitir una compra
static func play_cant_afford(node: Control) -> void:
	var origin_x: float = node.position.x
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "modulate", Color.RED, FLASH_DURATION)
	tween.parallel().tween_property(node, "position:x", origin_x + SHAKE_OFFSET, SHAKE_STEP)
	tween.tween_property(node, "position:x", origin_x - SHAKE_OFFSET, SHAKE_STEP)
	tween.tween_property(node, "position:x", origin_x, SHAKE_STEP)
	tween.parallel().tween_property(node, "modulate", Color.WHITE, FLASH_DURATION)
	
	_play_sound(node, SOUND_CANT_AFFORD)

static func play_confirm(node: Control) -> void:
	_play_sound(node, SOUND_CONFIRM)

static func play_unlock(node: Control) -> void:
	_play_sound(node, SOUND_UNLOCK)

static func play_back(node: Control) -> void:
	_play_sound(node, SOUND_BACK)

static func play_pause(node: Control) -> void:
	_play_sound(node, SOUND_PAUSE)

# Helper privado: crea un AudioStreamPlayer temporal anclado al árbol del nodo
static func _play_sound(node: Control, stream: AudioStream, pitch: float = 1.0) -> void:
	if not stream:
		return
		
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "SFX"
	player.pitch_scale = pitch + randf_range(-0.03, 0.03)

	node.add_child(player)
	player.play()

	player.finished.connect(player.queue_free)
