# Codex: muestra la colección completa de cartas, indicando cuáles están bloqueadas.
extends Control

@export var builder_card_scene: PackedScene

@onready var _collection_grid: GridContainer = %CollectionGrid

var _collection_ref: Array[CardData]

func _ready() -> void:
	_collection_ref = CardDatabase.all_cards
	update_ui()

func update_ui() -> void:
	var unlocked_ids: Array = GlobalData.save_file.unlocked_card_ids

	for child in _collection_grid.get_children():
		child.queue_free()

	for card in _collection_ref:
		var widget: Node = builder_card_scene.instantiate()
		_collection_grid.add_child(widget)
		widget.setup_codex(card, card.id not in unlocked_ids)

func _on_back_btn_pressed() -> void:
	UIFeedback.play_back(%BtnBack)
	hide()
