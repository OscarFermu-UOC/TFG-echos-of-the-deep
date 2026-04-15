# Recurso que define un tipo de enemigo spawnable: escena, stats y reglas de aparición por ciclo.
class_name EnemySpawnData
extends Resource

@export var enemy_scene: PackedScene
@export var name: String = "Enemy"
@export var stats: EnemyStats

@export_group("Spawn Rules")
@export var min_cycle: int = 1 # Ciclo mínimo a partir del cual puede aparecer
@export var base_weight: float = 10.0 # Peso en la tabla de spawn (mayor = más frecuente)
