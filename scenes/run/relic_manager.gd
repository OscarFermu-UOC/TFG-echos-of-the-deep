# Gestiona las reliquias activas de la run: aplica consumibles, activa pasivas y reacciona a eventos.
class_name RelicManager
extends Node

const VAMPIRISM_HEAL_AMOUNT: int = 10

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

	# Re-aplicamos las pasivas al cargar un nivel nuevo para que surtan efecto
	await get_tree().process_frame
	for id in GlobalData.current_run_relics:
		_on_passive_equipped(id)

# ==========================================================
# API PUBLICA
# ==========================================================
func add_relic(relic: RelicData) -> void:
	if relic.type == RelicData.Type.CONSUMABLE:
		_apply_consumable(relic)
		return
 
	if relic.id in GlobalData.current_run_relics:
		return
	GlobalData.current_run_relics.append(relic.id)
	EventBus.relic_obtained.emit(relic)
	_on_passive_equipped(relic.id)
 
func has_relic(id: String) -> bool:
	return id in GlobalData.current_run_relics
	
# ==========================================================
# CONSUMIBLES
# ==========================================================
func _apply_consumable(relic: RelicData) -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
 
	match relic.id:
		RelicIDs.HEAL:
			player.current_health = mini(player.current_health + int(relic.stat_value), player.max_health)
			EventBus.health_changed.emit(player.current_health, player.max_health)

# ==========================================================
# PASIVAS
# ==========================================================
func _on_passive_equipped(id: String) -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
 
	match id:
		RelicIDs.MOUSE_LIGHT:
			if player and player.has_node("MouseLight"):
				player.get_node("MouseLight").enabled = true

# ==========================================================
# REACTIVO
# ==========================================================
func _on_enemy_died() -> void:
	if not has_relic(RelicIDs.VAMPIRISM):
		return
	var player: Player = get_tree().get_first_node_in_group("Player")
	
	# Curamos al jugador si tiene la reliquia de vampirismo y no está al máximo de vida
	if player and player.current_health < player.max_health:
		player.current_health += VAMPIRISM_HEAL_AMOUNT
		EventBus.health_changed.emit(player.current_health, player.max_health)
