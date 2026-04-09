# Menú de pausa: gestiona la pausa del juego y da acceso a opciones y salida al menú principal.
extends CanvasLayer

const SCENE_MAIN_MENU: String = "res://ui/main_menu/main_menu.tscn"

@onready var _menu_buttons: VBoxContainer = %MenuButtons
@onready var _options_menu: Control = $Overlay/OptionsMenu

var _is_paused: bool = false

func _ready() -> void:
	hide()
	_options_menu.hide()
	
	if _options_menu.has_signal("back_pressed"):
		_options_menu.back_pressed.connect(_on_options_back)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
		
	if _options_menu.visible:
		_on_options_back()
	else:
		toggle_pause()

func toggle_pause() -> void:
	_is_paused = not _is_paused
	
	get_tree().paused = _is_paused
	visible = _is_paused
	
	_menu_buttons.visible = _is_paused
	_options_menu.hide()

func _on_btn_options_pressed() -> void:
	_menu_buttons.hide()
	_options_menu.show()

func _on_options_back() -> void:
	_options_menu.hide()
	_menu_buttons.show()

func _on_btn_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)
