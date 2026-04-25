# Base de datos de reliquias: indexa todas las reliquias por ID para acceso rápido.
extends Node

@export var all_relics: Array[RelicData] = []
var _relic_map: Dictionary = {}

func _ready() -> void:
	# Construimos el mapa ID -> RelicData al inicio
	for relic in all_relics:
		if relic.id.is_empty():
			push_warning("RelicDatabase: relic found with no ID — skipping.")
			continue
		_relic_map[relic.id] = relic

# Devuelve la RelicData correspondiente al ID, o null si no existe.
func get_relic_by_id(id: String) -> RelicData:
	return _relic_map.get(id, null)
