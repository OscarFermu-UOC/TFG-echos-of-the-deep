# Instancia etiquetas de daño flotantes en la posición donde se recibe el golpe.
extends Node

@export var floating_text_scene: PackedScene

func _ready() -> void:
	EventBus.damage_received.connect(_on_damage_received)

func _on_damage_received(amount: int, pos: Vector2, is_player: bool) -> void:
	if not floating_text_scene: return
	
	var text: Node = floating_text_scene.instantiate()
	add_child(text)
	
	text.global_position = pos
	text.setup(amount, is_player)
