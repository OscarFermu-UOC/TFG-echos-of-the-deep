# Workshop: pantalla de mejoras permanentes compradas con éter entre runs.
extends Control

@export var upgrade_item_scene: PackedScene
@export var all_upgrades: Array[UpgradeData] = []

@onready var _grid: GridContainer = %UpgradesGrid
@onready var _ether_label: Label = %EtherLabel

func _ready() -> void:
	all_upgrades.sort_custom(func(a, b): return a.title < b.title)
	_populate_grid()
	_update_currency_ui()

	if not EventBus.upgrade_requested.is_connected(_on_upgrade_requested):
		EventBus.upgrade_requested.connect(_on_upgrade_requested)

func _populate_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var saved: Dictionary = GlobalData.save_file.unlocked_upgrades
	for upgrade in all_upgrades:
		var widget: Node = upgrade_item_scene.instantiate()
		_grid.add_child(widget)
		widget.setup(upgrade, saved.get(upgrade.id, 0))

func _on_upgrade_requested(data: UpgradeData, cost: int, widget_node: WorkshopItem) -> void:
	if GlobalData.save_file.ether < cost:
		UIFeedback.play_cant_afford(widget_node)
		return

	GlobalData.save_file.ether -= cost

	var new_lvl: int = GlobalData.save_file.unlocked_upgrades.get(data.id, 0) + 1
	GlobalData.save_file.unlocked_upgrades[data.id] = new_lvl
	GlobalData.save()

	_update_currency_ui()
	widget_node.setup(data, new_lvl)
	
	# Actualizamos todos los botones por si alguno ya no puede permitirse
	_refresh_buttons_affordability()
	
	UIFeedback.play_unlock(widget_node)

func _update_currency_ui() -> void:
	_ether_label.text = "Ether: %d" % GlobalData.save_file.ether

func _refresh_buttons_affordability() -> void:
	for child in _grid.get_children():
		if child.has_method("_update_dynamic_state"):
			child._update_dynamic_state()

func _on_btn_back_pressed() -> void:
	UIFeedback.play_back(%BtnBack)
	get_parent().update_ui()
	hide()
