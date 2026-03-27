# Clase base de la que heredan todos los estados de la máquina de estados.
extends Node
class_name State

signal transitioned # Señal que emite el estado cuando quiere cambiar a otro

# Métodos a sobreescribir por cada estado concreto
func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
