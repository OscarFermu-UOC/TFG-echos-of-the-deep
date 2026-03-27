# Estado de stun
extends State
class_name EnemyStunned

@export var enemy: Enemy

var stun_duration: float = 0.0 # Se asigna desde fuera antes de entrar al estado

func enter() -> void:
	enemy.stop_movement()
	enemy.modulate = Color(0.5, 0.5, 1.5) 
	
	if enemy.audio_stun and enemy.audio_stun.stream:
		enemy.audio_stun.play()

func physics_update(delta) -> void:
	stun_duration -= delta
	if stun_duration <= 0.0:
		transitioned.emit(self, "Idle")

func exit() -> void:
	enemy.modulate = Color.WHITE 
