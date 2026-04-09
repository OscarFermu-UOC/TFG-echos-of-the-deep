# Menú de opciones: controla el volumen de los buses de audio y el modo de pantalla completa.
extends Control

signal back_pressed

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fullscreen_check: CheckBox = %FullscreenCheck
@onready var _back_button: Button = %BackButton

var _master_bus: int
var _music_bus: int
var _sfx_bus: int

func _ready() -> void:
	_master_bus = AudioServer.get_bus_index(BUS_MASTER)
	_music_bus = AudioServer.get_bus_index(BUS_MUSIC)
	_sfx_bus = AudioServer.get_bus_index(BUS_SFX)

	# Inicializamos los sliders con los valores actuales de cada bus
	_master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(_master_bus))
	_music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(_music_bus))
	_sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(_sfx_bus))

	_fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_back_button.pressed.connect(func(): back_pressed.emit())

func _on_master_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_master_bus, linear_to_db(value))

func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(value))

func _on_sfx_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(value))

func _on_fullscreen_toggled(toggled: bool) -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
