# HUD de reliquias: muestra los iconos de las reliquias activas en la run actual.
extends CanvasLayer

@export var relic_icon_scene: PackedScene

@onready var _grid: HBoxContainer = %RelicShelf

func _ready() -> void:
	EventBus.relic_obtained.connect(_add_relic_icon)
	await get_tree().process_frame
	_load_existing_relics()

func _load_existing_relics() -> void:
	for child in _grid.get_children():
		child.queue_free()
	for relic_id in GlobalData.current_run_relics:
		var relic_data: RelicData = RelicDatabase.get_relic_by_id(relic_id)
		if relic_data:
			_add_relic_icon(relic_data)

func _add_relic_icon(relic: RelicData) -> void:
	# Evitamos duplicados si la señal se emite para una reliquia ya mostrada
	for child in _grid.get_children():
		if child.get("my_relic") == relic:
			return
			
	var icon: Node = relic_icon_scene.instantiate()
	_grid.add_child(icon)
	icon.setup(relic)
