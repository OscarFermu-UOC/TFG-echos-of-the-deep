# Clase base de la que heredan todos los estados de la máquina de estados.
extends Node
class_name State

signal Transitioned # Señal que emite el estado cuando quiere cambiar a otro

# Métodos a sobreescribir por cada estado concreto
func Enter():
	pass
	
func Exit():
	pass
	
func Update(_delta: float):
	pass

func Physics_Update(_delta: float):
	pass
