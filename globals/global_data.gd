# Autoload que centraliza el estado global del juego: partida guardada, run actual y navegación.
class_name Global_Data
extends Node

# ==========================================================
# CONFIGURACIÓN
# ==========================================================
const MAX_CYCLES: int = 3
const MAX_STAGES: int = 3
const ETHER_CONVERSION_RATE: float = 0.1 # 10 de oro = 1 de éter

# ==========================================================
# ESTADO PERSISTENTE
# ==========================================================
var save_file: SaveGame
var game_completed: bool = false

# ==========================================================
# ESTADO DE LA RUN
# ==========================================================
var current_class_data: CharacterClass
var current_run_deck: Array[CardData] = []
var temp_run_gold: int = 0
var temp_run_ether: int = 0
var current_cycle: int = 1
var current_stage: int = 0
var current_player_hp: int = -1 # -1 significa usar la salud por defecto de la clase
var current_run_relics: Array[String] = []

# ==========================================================
# ESTADO DE NAVEGACIÓN
# ==========================================================
var current_depth: int = 1
var max_depth_for_cycle: int = 1
var is_ascending: bool = false
var has_dungeon_key: bool = false

# ==========================================================
# REFERENCIAS GLOBALES
# ==========================================================
var target: Node2D = null
var current_artifact_data: ArtifactData = null
var max_clank_reached: bool = false

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	_load_or_create_save()
	save_file.ether = 100
	save_file.unlocked_upgrades.clear()

# ==========================================================
# SAVE / LOAD
# ==========================================================
func _load_or_create_save() -> void:
	save_file = SaveGame.load_data()
	if not save_file:
		save_file = SaveGame.new()
		_setup_new_profile()
		save_file.save_data()

func save() -> void:
	if save_file:
		save_file.save_data()

func _setup_new_profile() -> void:
	save_file.ether = 0
	save_file.unlocked_card_ids = []
	save_file.unlocked_upgrades = {}
	save_file.unlocked_classes = ["scavenger"] # Clase inicial siempre disponible

# ==========================================================
# RUN SESSION
# ==========================================================
func start_new_run_session(selected_class: CharacterClass) -> void:
	temp_run_gold = 0
	temp_run_ether = 0
	current_cycle = 1
	current_stage = 1
	current_player_hp = -1

	current_class_data = selected_class
	current_run_deck.clear()
	current_run_relics.clear()

	current_depth = 1
	max_depth_for_cycle = current_cycle
	is_ascending = false
	has_dungeon_key = false

	target = null
	current_artifact_data = null
	max_clank_reached = false

func advance_stage() -> void:
	current_stage += 1

	if current_stage > MAX_STAGES:
		current_stage = 1
		current_cycle += 1

	if current_cycle > MAX_CYCLES:
		game_completed = true
		return

	push_warning("Advanced to Cycle %d — Stage %d." % [current_cycle, current_stage])
