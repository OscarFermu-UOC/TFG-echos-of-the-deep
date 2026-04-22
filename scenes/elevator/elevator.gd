# Pantalla entre stages: permite elegir una carta del draft, convertir el oro en éter o continuar.
extends Control

const SCENE_MAIN_MENU: String = "res://ui/main_menu/main_menu.tscn"
const SCENE_RUN: String = "res://scenes/run/run.tscn"
const SCENE_SANCTUARY: String = "res://scenes/sanctuary/sanctuary.tscn"
const SCENE_GAME_WIN: String = "res://scenes/game_win/game_win.tscn"

const DISCOVERY_BASE_CHANCE: float = 0.1
const DISCOVERY_CHANCE_PER_CYCLE: float = 0.2 # La probabilidad de descubrir cartas nuevas sube con el ciclo
const DRAFT_BASE_AMOUNT: int = 3
const NEW_CARD_MODULATE: Color = Color(1.5, 1.2, 2.0) # Tinte morado para cartas no descubiertas

@export var draft_card_scene: PackedScene

@onready var _title_label: Label = %TitleLabel
@onready var _loot_label: Label = %LootLabel
@onready var _draft_section: VBoxContainer = %DraftSection
@onready var _draft_container: HBoxContainer = %DraftContainer
@onready var _buttons_container: HBoxContainer = %ButtonsContainer
@onready var _btn_extract: Button = %BtnExtract

func _ready() -> void:
	var is_cycle_end: bool = GlobalData.current_stage == GlobalData.MAX_STAGES
	_title_label.text = "CYCLE %d COMPLETED" % GlobalData.current_cycle \
		if is_cycle_end \
		else "CYCLE %d - STAGE %d CLEARED" % [GlobalData.current_cycle, GlobalData.current_stage]

	_loot_label.text = "Run Loot: %d Gold" % GlobalData.temp_run_gold

	var ether_value: int = int(GlobalData.temp_run_gold * GlobalData.ETHER_CONVERSION_RATE)
	_btn_extract.text = "EXTRACT (+%d Ether)" % ether_value

	if not EventBus.card_clicked.is_connected(_on_draft_card_selected):
		EventBus.card_clicked.connect(_on_draft_card_selected)

	# Al final del ciclo no hay draft, se muestran directamente los botones de acción
	if is_cycle_end:
		_draft_section.hide()
		_buttons_container.show()
	else:
		_generate_draft()

func _generate_draft() -> void:
	for child in _draft_container.get_children():
		child.queue_free()

	var discovery_chance: float = DISCOVERY_BASE_CHANCE + GlobalData.current_cycle * DISCOVERY_CHANCE_PER_CYCLE
	var options: Array[CardData] = CardDatabase.get_draft_options(DRAFT_BASE_AMOUNT, discovery_chance)

	var unlocked_ids: Array = GlobalData.save_file.unlocked_card_ids
	for card in options:
		var widget: Node = draft_card_scene.instantiate()
		_draft_container.add_child(widget)
		widget.setup(card)
		
		# Las cartas no descubiertas se tiñen para destacarlas visualmente
		if card.id not in unlocked_ids:
			widget.modulate = NEW_CARD_MODULATE

func _on_draft_card_selected(card: CardData, _widget_node: Control) -> void:
	if _buttons_container.visible:
		return

	GlobalData.current_run_deck.append(card)

	# Si es una carta nueva, la registramos en el save
	var save: SaveGame = GlobalData.save_file
	if card.id not in save.unlocked_card_ids:
		save.unlocked_card_ids.append(card.id)
		save.save_data()

	_draft_section.hide()
	_buttons_container.show()
	_loot_label.text += "\nAcquired: " + card.title

func _on_btn_extract_pressed() -> void:
	GlobalData.save_file.ether += int(GlobalData.temp_run_gold * GlobalData.ETHER_CONVERSION_RATE)

	GlobalData.temp_run_gold = 0
	GlobalData.current_run_deck.clear()
	GlobalData.save()
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func _on_btn_descend_pressed() -> void:
	GlobalData.advance_stage()
	GlobalData.save()

	if GlobalData.game_completed:
		get_tree().change_scene_to_file(SCENE_GAME_WIN)
		return

	# El sanctuary aparece en el stage final de cada ciclo
	var next_scene: String = SCENE_SANCTUARY if GlobalData.current_stage == GlobalData.MAX_STAGES else SCENE_RUN
	get_tree().change_scene_to_file(next_scene)
