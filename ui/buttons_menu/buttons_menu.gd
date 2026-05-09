# Menú de controles: permite remapear los controles del juego.
extends Control

signal back_pressed
@onready var _back_button: Button = %BackButton

func _ready() -> void:
	_back_button.pressed.connect(func(): back_pressed.emit())
