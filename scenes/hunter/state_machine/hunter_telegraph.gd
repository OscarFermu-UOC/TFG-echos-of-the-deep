# Estado de telegrafía del Hunter: se detiene, avisa visualmente y lanza el dash tras un breve delay.
extends State
class_name HunterTelegraph

const TELEGRAPH_FLASH_DURATION: float = 0.2

@export var hunter: Hunter
var timer: float = 0.0

func enter() -> void:
	hunter.velocity = Vector2.ZERO 
	hunter.modulate.a = 1.0 # Vuelve a ser completamente visible
	
	# Flash rojo para avisar al jugador del ataque inminente
	var tween = create_tween()
	tween.tween_property(hunter.sprite, "modulate", Color.RED, TELEGRAPH_FLASH_DURATION)
	tween.tween_property(hunter.sprite, "modulate", Color.WHITE, TELEGRAPH_FLASH_DURATION)
	
	if hunter.telegraph_sound and hunter.telegraph_sound.stream:
		hunter.telegraph_sound.play()
	
	timer = hunter.telegraph_duration

func physics_update(delta) -> void:
	timer -= delta
	if timer <= 0:
		transitioned.emit(self, "Dash")
		return
	
	# Sigue apuntando al jugador hasta que el dash comienza
	hunter.face_player()
