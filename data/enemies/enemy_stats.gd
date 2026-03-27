# Recurso que define las estadísticas y parámetros de IA de un tipo de enemigo.
class_name EnemyStats
extends Resource

@export_group("Data")
@export var name: String
@export var texture: Texture2D

@export_group("Stats")
@export var max_health: int = 30
@export var damage: int = 10
@export var move_speed: float = 60.0

@export_group("AI Perception")
@export var detection_range: float = 200.0
@export var attack_range: float = 30.0
@export var stop_distance: float = 20.0
@export var min_safe_distance: float = 0.0 # Si es > 0 el enemigo es de tipo ranged y se retirará al estar cerca
@export var wander_radius: float = 100.0

@export_group("Ranged Data")
@export var projectile_scene: PackedScene
