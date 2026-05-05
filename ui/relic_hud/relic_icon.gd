# Icono individual de reliquia: muestra el tooltip al pasar el ratón y aparece con animación.
extends PanelContainer

const HOVER_MODULATE: Color = Color(1.2, 1.2, 1.2)
const POP_DURATION: float = 0.3

@onready var _icon: TextureRect = %Icon

var my_relic: RelicData

func setup(relic: RelicData) -> void:
	my_relic = relic
	_icon.texture = relic.icon

	pivot_offset = size / 2.0
	scale = Vector2.ZERO
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, POP_DURATION).set_trans(Tween.TRANS_BACK)
