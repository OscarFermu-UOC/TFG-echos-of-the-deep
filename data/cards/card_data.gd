# Recurso que define los datos de una carta: apariencia, rareza y lista de efectos que aplica.
class_name CardData
extends Resource

enum Rarity {
	COMMON,
	RARE,
	EPIC
}

@export_group("Visuals")
@export var id: String
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity

@export_group("Gameplay")
@export_range(1, 10, 1) var max_copies: int # Número máximo de copias permitidas en el mazo
@export var cost: int
@export var cooldown_mod: float = 0.0 # Modificador sobre el tiempo de robo base

@export var effects: Array[CardEffect]
