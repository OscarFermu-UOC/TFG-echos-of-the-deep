# Icono individual de reliquia: muestra el tooltip al pasar el ratón y aparece con animación.
extends PanelContainer

const HOVER_MODULATE: Color = Color(1.2, 1.2, 1.2)
const POP_DURATION: float = 0.3

@onready var _icon: TextureRect = %Icon

var my_relic: RelicData

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(relic: RelicData) -> void:
	my_relic = relic
	_icon.texture = relic.icon

	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).set_trans(Tween.TRANS_BACK)

func _on_mouse_entered() -> void:
	if not my_relic:
		return
		
	modulate = HOVER_MODULATE
	Tooltip.show_data(my_relic, "")

func _on_mouse_exited() -> void:
	modulate = Color.WHITE
	Tooltip.hide_tooltip()
