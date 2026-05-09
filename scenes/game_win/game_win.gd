# Pantalla de victoria: muestra título, subtítulo e icono al completar el juego.
extends RevealScreen

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _skull_icon: TextureRect = %SkullIcon
@onready var _btn_menu: Button = %BtnMenu

func _get_reveal_nodes() -> Array[Node]:
	return [_title, _subtitle, _skull_icon]

func _get_confirm_button() -> Button:
	return _btn_menu
