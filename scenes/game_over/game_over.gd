# Pantalla de game over: muestra las estadísticas de la run (oro y éter) antes de volver al menú.
extends RevealScreen

@onready var _title: Label = %Title
@onready var _stats_panel: PanelContainer = %StatsPanel
@onready var _gold_val: Label = %GoldValue
@onready var _ether_val: Label = %EtherValue
@onready var _btn_menu: Button = %BtnMenu

func _get_reveal_nodes() -> Array[Node]:
	return [_title, _stats_panel]

func _get_confirm_button() -> Button:
	return _btn_menu

func _ready() -> void:
	# El texto del oro cambia según si el jugador tenía la reliquia de seguro de vida
	if RelicIDs.LIFE_INSURANCE in GlobalData.current_run_relics:
		_gold_val.text = "Gold saved with Life Insurance - %d" % GlobalData.temp_run_gold
	else:
		_gold_val.text = "Gold lost - %d" % GlobalData.temp_run_gold
	_ether_val.text = "Ether saved - %d" % GlobalData.temp_run_ether
	super._ready()
