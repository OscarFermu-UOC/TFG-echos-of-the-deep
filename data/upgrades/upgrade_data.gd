# Recurso que define una mejora del Workshop: coste, niveles y previsualización del efecto.
class_name UpgradeData
extends Resource

@export_group("Identity")
@export var id: String
@export var title: String
@export var icon: Texture2D
@export_multiline var description: String

@export_group("Progression")
@export var max_level: int = 5
@export var base_cost: int = 2
@export var cost_increment: int = 4 # El coste aumenta esta cantidad por nivel
@export var stat_preview: String = "+10 HP" # Texto informativo mostrado en la UI
