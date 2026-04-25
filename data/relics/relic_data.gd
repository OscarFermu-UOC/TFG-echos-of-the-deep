# Recurso que define una reliquia.
class_name RelicData
extends Resource

enum Type { CONSUMABLE, PASSIVE }

@export var id: String = ""
@export var title: String
@export var icon: Texture2D
@export_multiline var description: String
@export var cost: int = 20
@export var type: Type

# Solo relevante para reliquias consumibles que modifican una stat concreta
@export_group("Stat Modifiers (Consumable)")
@export var stat_target: String = ""
@export var stat_value: float = 0.0
