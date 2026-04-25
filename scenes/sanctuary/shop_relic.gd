# item de reliquia en la tienda: muestra precio, permite comprarla y se marca como vendida.
class_name ShopRelic
extends PanelContainer

const HOVER_MODULATE: Color = Color(1.25, 1.25, 1.25)
const COLOR_PRICE: Color = Color(1.0, 0.8, 0.2)
const COLOR_SOLD: Color = Color(0.3, 0.3, 0.3)

var relic_data: RelicData

func setup_relic(relic: RelicData) -> void:
	relic_data = relic
	%Icon.texture = relic.icon
	%Title.text = relic.title
	%Description.text = relic.description
	%ExtraInfo.text = "%d G" % relic.cost
	%ExtraInfo.modulate = COLOR_PRICE

func mark_as_sold() -> void:
	modulate = COLOR_SOLD
	%ExtraInfo.text = "SOLD"
	mouse_filter = Control.MOUSE_FILTER_IGNORE # Desactivamos la interacción al estar vendida

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		EventBus.buy_requested.emit(relic_data, self)
