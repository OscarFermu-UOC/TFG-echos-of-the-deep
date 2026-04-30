# Widget de mejora individual del Workshop: muestra nivel, coste y gestiona la compra.
class_name WorkshopItem
extends PanelContainer

const COLOR_CANT_AFFORD: Color = Color(1.0, 0.5, 0.5)
const COLOR_MAXED: Color = Color(0.7, 0.7, 0.7)

@onready var _icon: TextureRect = %Icon
@onready var _title: Label = %Title
@onready var _lvl_label: Label = %LevelLabel
@onready var _desc: Label = %Description
@onready var _stat_label: Label = %StatPreview
@onready var _buy_button: Button = %BuyButton

var _data: UpgradeData
var _current_level: int = 0
var _next_cost: int = 0

func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_button_pressed)

func setup(data: UpgradeData, saved_level: int) -> void:
	_data = data
	_current_level = saved_level
	_icon.texture = data.icon
	_title.text = data.title
	_desc.text = data.description
	_stat_label.text = data.stat_preview
	_update_dynamic_state()

func _update_dynamic_state() -> void:
	# Fórmula de coste: base + nivel_actual * incremento
	_next_cost = _data.base_cost + _current_level * _data.cost_increment
	_lvl_label.text = "Lvl %d / %d" % [_current_level, _data.max_level]

	if _current_level >= _data.max_level:
		_buy_button.disabled = true
		_buy_button.text = "MAXED"
		modulate = COLOR_MAXED
	else:
		modulate = Color.WHITE
		_buy_button.disabled = false
		_buy_button.text = "%d Ether" % _next_cost
		_buy_button.modulate = Color.WHITE if GlobalData.save_file.ether >= _next_cost else COLOR_CANT_AFFORD

func _on_buy_button_pressed() -> void:
	EventBus.upgrade_requested.emit(_data, _next_cost, self)
