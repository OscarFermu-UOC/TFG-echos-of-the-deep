# Base de datos de artefactos organizada en tres tiers según el ciclo de la run.
class_name ArtifactDatabase
extends Resource

@export_group("Tier 1 (Early Game)")
@export var tier_1: Array[ArtifactData]

@export_group("Tier 2 (Mid Game)")
@export var tier_2: Array[ArtifactData]

@export_group("Tier 3 (End Game)")
@export var tier_3: Array[ArtifactData]

func get_random_artifact_for_level(cycle: int) -> ArtifactData:
	var pool: Array[ArtifactData] = _pool_for_cycle(cycle)
 
	if pool.is_empty():
		push_error("ArtifactDatabase: no artifacts defined for cycle %d." % cycle)
		return null
 
	return pool.pick_random()
 
func _pool_for_cycle(cycle: int) -> Array[ArtifactData]:
	match cycle:
		1: return tier_1
		2: return tier_2
		3: return tier_3
		_: return tier_3 # Por defecto usamos el tier más alto
