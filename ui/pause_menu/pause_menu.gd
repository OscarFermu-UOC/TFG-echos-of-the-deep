extends CanvasLayer

@onready var menu_buttons: VBoxContainer = %MenuButtons
@onready var btn_resume: Button = %BtnResume
@onready var btn_options: Button = %BtnOptions
@onready var btn_quit: Button = %BtnQuit
@onready var options_menu: Control = $Overlay/OptionsMenu

var is_paused: bool = false

func _ready() -> void:
	hide()
	options_menu.hide()	
	
	if options_menu.has_signal("back_pressed"):
		options_menu.back_pressed.connect(_on_options_back)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"): # Tecla ESC
		if options_menu.visible:
			options_menu.hide()
		else:
			toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		menu_buttons.show()
		options_menu.hide()
	else:
		options_menu.hide()

func _on_btn_options_pressed() -> void:
	menu_buttons.hide()
	options_menu.show()
	
func _on_options_back() -> void:
	options_menu.hide()
	menu_buttons.show()

func _on_btn_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
