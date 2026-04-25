# Tienda del santuario: ofrece reliquias al jugador con opción de reroll y compra con oro.
class_name SanctuaryShopUI
extends Control

const SCENE_ELEVATOR: String = "res://scenes/elevator/elevator.tscn"
const COLOR_REROLL_DISABLED: Color = Color(0.7, 0.7, 0.7)

@export_group("Shop Settings")
@export var shop_item_scene: PackedScene
@export var items_to_offer: int = 3

@export_group("Reroll Settings")
@export var base_reroll_cost: int = 5
@export var reroll_cost_increment: int = 3 # El coste de reroll sube cada vez que se usa

@onready var _items_container: HBoxContainer = %ItemsContainer
@onready var _money_label: Label = %CurrencyLabel
@onready var _btn_reroll: Button = %BtnReroll

var _current_reroll_cost: int = 0
var _full_item_pool: Array[RelicData] = []

func _ready() -> void:
	_update_ui()
	if not EventBus.buy_requested.is_connected(_on_buy_requested):
		EventBus.buy_requested.connect(_on_buy_requested)
		
	populate(RelicDatabase.all_relics)

# ==========================================================
# API PUBLICA
# ==========================================================
func populate(pool: Array[RelicData]) -> void:
	_full_item_pool = pool
	_current_reroll_cost = 0 if RelicIDs.FREE_REROLL in GlobalData.current_run_relics else base_reroll_cost
	_generate_offer()
	_update_ui()

# ==========================================================
# INTERNAL
# ==========================================================
func _generate_offer() -> void:
	for child in _items_container.get_children():
		child.queue_free()

	var shuffled: Array[RelicData] = _full_item_pool.duplicate()
	shuffled.shuffle()

	for item_data in shuffled.slice(0, items_to_offer):
		var widget: Node = shop_item_scene.instantiate()
		_items_container.add_child(widget)
		widget.setup_relic(item_data)

func _update_ui() -> void:
	_money_label.text = "Gold: %d" % GlobalData.temp_run_gold
	_update_reroll_ui()

func _update_reroll_ui() -> void:
	_btn_reroll.text = "Reroll (%d)" % _current_reroll_cost
	var can_afford: bool = GlobalData.temp_run_gold >= _current_reroll_cost
	_btn_reroll.disabled = not can_afford
	_btn_reroll.modulate = Color.WHITE if can_afford else COLOR_REROLL_DISABLED

# ==========================================================
# COMPRA
# ==========================================================
func _on_buy_requested(item_data: RelicData, widget_node: Control) -> void:
	if not is_visible_in_tree():
		return

	if GlobalData.temp_run_gold < item_data.cost:
		# Animation
		return

	GlobalData.temp_run_gold -= item_data.cost
	GlobalData.current_run_relics.append(item_data.id)
	_update_ui()
	widget_node.mark_as_sold()

# ==========================================================
# REROLL Y EXIT
# ==========================================================
func _on_btn_reroll_pressed() -> void:
	if GlobalData.temp_run_gold < _current_reroll_cost:
		# Animation
		return

	GlobalData.temp_run_gold -= _current_reroll_cost
	_current_reroll_cost += reroll_cost_increment
	_generate_offer()
	_update_ui()

func _on_btn_back_pressed() -> void:
	get_tree().paused = false

	set_process_unhandled_input(false)
	get_tree().change_scene_to_file(SCENE_ELEVATOR)
