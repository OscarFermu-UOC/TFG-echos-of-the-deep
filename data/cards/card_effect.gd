# Recurso que representa un efecto individual de una carta con su tipo, valor y probabilidad.
class_name CardEffect
extends Resource

enum Type {
	BLOCK_CLANK,
	BLOCK_HAZARD,
	GENERATE_LOOT,
	MODIFY_SPEED,
	GLOBAL_STUN,
	ADD_CLANK,
	DRAW_CARD,
	SPECIAL_SCALING,
	CONVERT_RESOURCE,
}

@export var type: Type
@export var value: int = 0
@export_range(0.0, 1.0) var chance: float = 1.0 # Probabilidad de que el efecto se aplique
@export var custom_id: String = "" # Identificador para efectos especiales
