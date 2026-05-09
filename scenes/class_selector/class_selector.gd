# Selector de clase: permite elegir y desbloquear clases antes de iniciar una run.
extends Control

const SCENE_RUN: String = "res://scenes/run/run.tscn"
const COLOR_LOCKED_CLASS: Color = Color(0.7, 0.7, 0.7)
const COLOR_UNLOCK_AFFORDABLE: Color = Color(0.5, 1.0, 0.5)
const COLOR_UNLOCK_UNAFFORDABLE: Color = Color(1.0, 0.4, 0.4)
const BUTTON_MARGIN_LEFT: int = 20
const BUTTON_MARGIN_TOP: int = 10

@export var available_classes: Array[CharacterClass] = []

@onready var _buttons_container: VBoxContainer = %ClassButtonsContainer
@onready var _portrait: TextureRect = %Portrait
@onready var _name_label: Label = %ClassName
@onready var _stats_label: RichTextLabel = %StatsInfo
@onready var _btn_confirm: Button = %BtnConfirm

var _selected_class: CharacterClass = null

func _ready() -> void:
	available_classes.sort_custom(_sort_classes)
	_populate_list()
	if not available_classes.is_empty():
		_select_class(available_classes[0])

# Las clases desbloqueadas aparecen primero, y dentro de cada grupo se ordenan por coste
func _sort_classes(a: CharacterClass, b: CharacterClass) -> bool:
	var unlocked: Array = GlobalData.save_file.unlocked_classes
	var a_unlocked: bool = a.id in unlocked
	var b_unlocked: bool = b.id in unlocked
	if a_unlocked != b_unlocked:
		return a_unlocked
	return a.unlock_cost < b.unlock_cost

func _populate_list() -> void:
	for child in _buttons_container.get_children():
		child.queue_free()

	var unlocked_ids: Array = GlobalData.save_file.unlocked_classes
	for c_data in available_classes:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", BUTTON_MARGIN_LEFT)
		margin.add_theme_constant_override("margin_top", BUTTON_MARGIN_TOP)

		var btn := Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

		if c_data.id in unlocked_ids:
			btn.text = c_data.char_name
			btn.modulate = Color.WHITE
		else:
			btn.text = "[LOCKED] " + c_data.char_name
			btn.modulate = COLOR_LOCKED_CLASS

		btn.pressed.connect(_select_class.bind(c_data))
		margin.add_child(btn)
		_buttons_container.add_child(margin)

func _select_class(c_data: CharacterClass) -> void:
	_selected_class = c_data

	if c_data.portrait:
		_portrait.texture = c_data.portrait
	_name_label.text = c_data.char_name

	var weapon_name: String = c_data.starting_weapon.name if c_data.starting_weapon else "None"
	_stats_label.text = "[b]Base Stats:[/b]\n - Health: %d\n - Speed: %d\n\n[b]Starting Weapon:[/b]\n%s" % [c_data.max_health, c_data.walk_speed, weapon_name]

	var is_unlocked: bool = c_data.id in GlobalData.save_file.unlocked_classes
	if is_unlocked:
		_btn_confirm.text = "EMBARK"
		_btn_confirm.modulate = Color.WHITE
	else:
		_btn_confirm.text = "UNLOCK (%d Ether)" % c_data.unlock_cost
		# Verde si puede permitírselo, rojo si no
		_btn_confirm.modulate = COLOR_UNLOCK_AFFORDABLE if GlobalData.save_file.ether >= c_data.unlock_cost else COLOR_UNLOCK_UNAFFORDABLE

func _on_btn_confirm_pressed() -> void:
	if not _selected_class:
		return

	var is_unlocked: bool = _selected_class.id in GlobalData.save_file.unlocked_classes
	if is_unlocked:
		GlobalData.start_new_run_session(_selected_class)
		SceneTransition.change_scene_to_file(SCENE_RUN)
		return

	if GlobalData.save_file.ether < _selected_class.unlock_cost:
		UIFeedback.play_cant_afford(_btn_confirm)
		return

	GlobalData.save_file.ether -= _selected_class.unlock_cost
	GlobalData.save_file.unlocked_classes.append(_selected_class.id)
	GlobalData.save()
	
	UIFeedback.play_unlock(_btn_confirm)
	
	_populate_list()
	_select_class(_selected_class)

func _on_btn_back_pressed() -> void:
	UIFeedback.play_back(_btn_confirm)
	
	get_parent().update_ui()
	hide()
