# Recurso persistente que almacena el progreso del jugador entre partidas.
class_name SaveGame
extends Resource

const SAVE_PATH: String = "user://savegame.tres"

# ==========================================================
# PERSISTENT DATA
# ==========================================================
@export var ether: int = 0 # Moneda permanente entre runs
@export var unlocked_card_ids: Array[String] = [] # Cartas descubiertas al menos una vez
@export var unlocked_upgrades: Dictionary = {} # Mejoras compradas (ID, nivel)
@export var unlocked_classes: Array[String] = ["scavenger"] # Clases disponibles al inicio

# ==========================================================
# PERSISTENCE
# ==========================================================
func save_data() -> void:
	var err: Error = ResourceSaver.save(self, SAVE_PATH)
	if err != OK:
		push_error("SaveGame: failed to save (error %d)." % err)

static func load_data() -> SaveGame:
	if FileAccess.file_exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH) as SaveGame
	return null

static func delete_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
