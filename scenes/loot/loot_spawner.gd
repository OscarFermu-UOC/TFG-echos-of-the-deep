# Spawner individual de loot: genera objetos periódicamente con pesos configurables por tipo.
class_name LootSpawner
extends Node2D

const MIN_SPAWN_INTERVAL_MULT: float = 0.2 # Límite inferior del multiplicador de velocidad de spawn
const CHANCE_BONUS_PER_POWER: float = 0.05 # Bonus de probabilidad por nivel de boost
const INTERVAL_MULT_PER_POWER: float = 0.05 # Reducción del intervalo por nivel de boost

var _spawn_interval: float
var _spawn_chance: float
var _coin_weight: float
var _key_weight: float
var _ether_weight: float

var _coin_scene: PackedScene
var _key_scene: PackedScene
var _ether_scene: PackedScene

var _timer: Timer
var _current_loot: Node = null # Referencia al loot activo; evita spawnear si ya hay uno
var _loot_manager: LootManager

func _ready() -> void:
	add_to_group("LootSpawners")
	_loot_manager = get_tree().get_first_node_in_group("LootManager")
	
	if not _loot_manager:
		push_warning("LootSpawner: no LootManager found in scene.")
		return

	# Copiamos la configuración del LootManager central
	_spawn_interval = _loot_manager.spawn_interval
	_spawn_chance = _loot_manager.spawn_chance
	_coin_weight = _loot_manager.coin_weight
	_key_weight = _loot_manager.key_weight
	_ether_weight = _loot_manager.ether_weight
	_coin_scene = _loot_manager.coin_scene
	_key_scene = _loot_manager.key_scene
	_ether_scene = _loot_manager.ether_scene

	_timer = Timer.new()
	_timer.wait_time = _spawn_interval
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_spawn_attempt)
	
	# Desfasamos el inicio para que los spawners no actúen todos a la vez
	_timer.start(randf() * _spawn_interval)

func _on_spawn_attempt() -> void:
	if not _loot_manager:
		return
	if _current_loot and _current_loot.is_inside_tree():
		return # Ya hay un loot activo en este spawner
	if randf() > _spawn_chance:
		return

	var scene: PackedScene = _pick_loot_scene()
	if not scene:
		return

	var obj: Node2D = scene.instantiate()
	get_parent().call_deferred("add_child", obj)
	obj.global_position = global_position
	_current_loot = obj
	obj.tree_exited.connect(_on_loot_collected)

func _pick_loot_scene() -> PackedScene:
	# Selección aleatoria ponderada entre los tres tipos de loot
	var total: float = _coin_weight + _key_weight + _ether_weight
	var roll: float = randf() * total

	if roll < _coin_weight:
		return _coin_scene
	elif roll < _coin_weight + _key_weight:
		# Si el jugador ya tiene llave, damos éter en su lugar para evitar duplicados
		return _ether_scene if GlobalData.has_dungeon_key else _key_scene
	else:
		return _ether_scene

func apply_generation_boost(power: int) -> void:
	_spawn_chance = clampf(_spawn_chance + CHANCE_BONUS_PER_POWER * power, 0.0, 1.0)

	var speed_mult: float = maxf(1.0 - INTERVAL_MULT_PER_POWER * power, MIN_SPAWN_INTERVAL_MULT)
	_spawn_interval *= speed_mult

	if not _timer.is_stopped():
		_timer.wait_time = _spawn_interval

func _on_loot_collected() -> void:
	_current_loot = null
	_timer.start(_spawn_interval)
