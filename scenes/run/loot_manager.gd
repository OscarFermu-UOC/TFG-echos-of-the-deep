# Gestiona la economía de loot: cuenta monedas, persiste el éter y coordina los spawners.
class_name LootManager
extends Node

# ==========================================================
# CONSTANTES
# ==========================================================
const LOOT_COIN_DEFAULT: int = 1

# ==========================================================
# CONFIGURACIÓN
# ==========================================================
@export_group("Loot Settings")
@export var spawn_interval: float = 20.0
@export_range(0.0, 1.0) var spawn_chance: float = 0.20
@export_range(0.0, 1.0) var coin_weight: float = 0.65
@export_range(0.0, 1.0) var key_weight: float = 0.25
@export_range(0.0, 1.0) var ether_weight: float = 0.1

# ==========================================================
# REFERENCIAS
# ==========================================================
@export_group("Loot Scenes")
@export var coin_scene: PackedScene
@export var key_scene: PackedScene
@export var ether_scene: PackedScene

# ==========================================================
# ESTADO
# ==========================================================
var coins: int = 0

func _ready() -> void:
	add_to_group("LootManager")
	
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.ether_collected.connect(_on_ether_collected)
	EventBus.key_collected.connect(_on_key_collected)
	EventBus.key_used.connect(_on_key_used)

func _on_coin_collected() -> void:
	# Si el jugador tiene la reliquia de loot, cada moneda vale más
	coins += LOOT_COIN_DEFAULT
	
func _on_ether_collected() -> void:
	GlobalData.save_file.ether += 1
	GlobalData.temp_run_ether += 1
	GlobalData.save() 

func _on_key_collected() -> void:
	GlobalData.has_dungeon_key = true
	
func _on_key_used() -> void:
	GlobalData.has_dungeon_key = false
	
func boost_all_spawners(power: int) -> void:
	get_tree().call_group("LootSpawners", "apply_generation_boost", power)
