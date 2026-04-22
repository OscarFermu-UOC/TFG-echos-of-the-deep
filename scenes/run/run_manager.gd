# Núcleo de la partida: coordina la generación del nivel, los sistemas de juego y las transiciones entre plantas.
class_name RunManager
extends Node

# ==========================================================
# CONSTANTES
# ==========================================================
const SCENE_ELEVATOR: String = "res://scenes/elevator/elevator.tscn"
const SCENE_GAME_OVER: String = "res://scenes/game_over/game_over.tscn"
const DEATH_PAUSE_DURATION: float = 1.5
const FLOOR_TRANSITION_DELAY: float = 0.5
const LIFE_INSURANCE_GOLD_KEPT: float = 0.5 # Fracción de oro conservada con la reliquia LIFE_INSURANCE

# Constantes para los efectos especiales de las cartas
const HP_TO_BLOCK_BASE: int = 1
const HP_HEART_SIZE: float = 20.0
const HAZARD_TO_SPEED_MAX_CONSUME: int = 5
const HAZARD_SPEED_PER_POINT: float = 10.0
const CLANK_SPEED_PER_POINT: float = 5.0
const CLANK_SPEED_DURATION: float = 5.0
const ARTIFACT_SHIELD_DEFAULT: int = 2
const ARTIFACT_SHIELD_ASCENDING: int = 10
const BLOCK_TO_LOOT_THRESHOLD: int = 5
const BLOCK_TO_LOOT_HIGH_POWER: int = 3
const STORM_EYE_HAZARD_BLOCK: int = 10
const STORM_EYE_STUN_DURATION: float = 3.0
const STORM_EYE_FLASH_IN: float = 0.1
const STORM_EYE_FLASH_OUT: float = 0.5
 
# ==========================================================
# REFERENCIAS
# ==========================================================
@onready var map_generator: MapGenerator = %MapGenerator
@onready var clank_system: ClankManager = $ClankManager
@onready var hazard_system: HazardManager = $HazardManager
@onready var card_manager: CardManager = $CardManager
@onready var loot_manager: LootManager = $LootManager

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	add_to_group("RunManager")
	
	EventBus.run_successful.connect(_on_run_successful)
	EventBus.player_died.connect(_on_player_died)
	EventBus.card_played.connect(_on_card_played)
	EventBus.threshold_reached.connect(_on_hunter_summon)
	EventBus.artifact_picked_up.connect(_on_artifact_picked_up)
	EventBus.stairs_used.connect(_on_stairs_used)
		
	get_tree().paused = false
	
	# Esperamos dos frames para que todos los nodos hijos estén completamente en el árbol
	await get_tree().process_frame
	await get_tree().process_frame
	start_new_run()

# ==========================================================
# RUN SETUP
# ==========================================================
func start_new_run() -> void:
	var cycle: int = GlobalData.current_cycle
	var stage: int = GlobalData.current_stage
		
	GlobalData.current_depth = 1
	GlobalData.max_depth_for_cycle = cycle 
	GlobalData.is_ascending = false
	GlobalData.has_dungeon_key = false

	# Solo inicializamos al jugador desde cero en el primer stage del primer ciclo
	if stage == 1 and cycle == 1 and GlobalData.current_class_data:
		GlobalData.temp_run_gold    = 0
		GlobalData.current_run_deck = GlobalData.current_class_data.starting_deck.duplicate()
		%Player.stats = GlobalData.current_class_data
		%Player._initialize_character()

	_generate_dungeon_level(stage)
	_update_compass_logic()

	card_manager.start_deck_cycle(GlobalData.current_run_deck)

	hazard_system.reset()
	clank_system.reset()

	# Restauramos la salud del jugador si viene de una planta anterior
	if GlobalData.current_player_hp > 0:
		%Player.current_health = GlobalData.current_player_hp
		EventBus.health_changed.emit(%Player.current_health, %Player.max_health)

func _generate_dungeon_level(stage: int) -> void:
	map_generator.generate_dungeon(stage)
	
# ==========================================================
# LOGICA DE LA BRUJULA
# ==========================================================
func _update_compass_logic() -> void:
	var target_node: Node2D = _find_compass_target()
	
	if target_node:
		GlobalData.target = target_node
		EventBus.compass_target_changed.emit()
 
func _find_compass_target() -> Node2D:
	# Al bajar apuntamos al artefacto en la planta más profunda, o a las escaleras
	if not GlobalData.is_ascending:
		if GlobalData.current_depth == GlobalData.max_depth_for_cycle:
			return get_tree().get_first_node_in_group("Artifact")
		return get_tree().get_first_node_in_group("StairsDown")
	# Al ascender apuntamos a la salida en la planta 1, o a las escaleras de subida
	else:
		if GlobalData.current_depth == 1:
			return get_tree().get_first_node_in_group("Exit")
		return get_tree().get_first_node_in_group("StairsUp")

# ==========================================================
# NAVEGACIÓN Y PROFUNDIDAD
# ==========================================================
func _on_stairs_used(type: int) -> void:
	await get_tree().create_timer(FLOOR_TRANSITION_DELAY).timeout
 
	if type == DungeonStairs.Type.DOWN:
		GlobalData.current_depth += 1
		GlobalData.has_dungeon_key = false
	elif type == DungeonStairs.Type.UP:
		GlobalData.current_depth -= 1
 
	_generate_dungeon_level(GlobalData.current_stage)
	await get_tree().process_frame
	_update_compass_logic()
	
# ==========================================================
# EVENTOS DE ESTADO DE JUEGO
# ==========================================================	
func _on_run_successful(artifact: ArtifactData) -> void:
	get_tree().paused = false
	GlobalData.current_player_hp = %Player.current_health
	GlobalData.temp_run_gold += loot_manager.coins + artifact.value
	GlobalData.save()
	get_tree().change_scene_to_file(SCENE_ELEVATOR)
 
func _on_artifact_picked_up(artifact: ArtifactData) -> void:
	GlobalData.is_ascending = true
	GlobalData.current_artifact_data = artifact
	_update_compass_logic()
 
func _on_player_died() -> void:
	get_tree().paused = true
	GlobalData.temp_run_gold += loot_manager.coins
 
	var gold_saved: int = 0
 
	# El oro guardado se convierte parcialmente en éter permanente
	var saved_ether: int = int(gold_saved * GlobalData.ETHER_CONVERSION_RATE)
	GlobalData.save_file.ether += saved_ether
	GlobalData.temp_run_ether += saved_ether
	GlobalData.save()
 
	await get_tree().create_timer(DEATH_PAUSE_DURATION, true, false, true).timeout
	get_tree().change_scene_to_file(SCENE_GAME_OVER)
 
func _on_hunter_summon() -> void:
	map_generator.spawn_hunter()

# ==========================================================
# LÓGICA DE EFECTOS
# ==========================================================
func _on_card_played(card_data: CardData) -> void:
	for effect in card_data.effects:
		_apply_single_effect(effect)

func _apply_single_effect(effect: CardEffect) -> void:
	# Aplicamos el efecto solo si supera la tirada de probabilidad
	if effect.chance < 1.0 and randf() > effect.chance:
		return

	match effect.type:
		CardEffect.Type.BLOCK_CLANK:
			clank_system.add_clank_block(effect.value)
			
		CardEffect.Type.BLOCK_HAZARD:
			hazard_system.add_hazard_block(effect.value)
			
		CardEffect.Type.GENERATE_LOOT:
			loot_manager.boost_all_spawners(effect.value)
