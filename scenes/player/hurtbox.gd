# Área de colisión que recibe daño y lo redirige al nodo propietario.
extends Area2D
class_name Hurtbox

func take_damage(amount: int):
	# Comprobamos que el propietario tenga el método antes de llamarlo,
	# así este componente es reutilizable en cualquier entidad
	if owner.has_method("take_damage"):
		owner.take_damage(amount)
