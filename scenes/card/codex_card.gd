# Carta del codex: extiende BaseCard para mostrar cartas bloqueadas/desbloqueadas en la colección.
class_name CodexCard
extends BaseCard

const COLOR_LOCKED_CARD: Color = Color(0.7, 0.7, 0.7, 1.0)
const COLOR_DESCRIPTION: Color = Color(0.7, 0.7, 0.7)
const LOCKED_ICON_MODULATE: Color = Color(0.0, 0.0, 0.0, 1.0) # Icono negro para cartas bloqueadas
const LOCKED_TOOLTIP: String = "Find this card in the\ndepths to unlock its data"

var is_locked: bool = false

func setup_codex(card: CardData, locked: bool) -> void:
	super.setup(card)
	is_locked = locked

	if is_locked:
		%Icon.modulate = LOCKED_ICON_MODULATE
		%Title.text = "???"
		%ExtraInfo.text = "LOCKED"
		_tooltip_extra_info = LOCKED_TOOLTIP
		modulate = COLOR_LOCKED_CARD
	else:
		%Icon.modulate = Color.WHITE
		%ExtraInfo.text = card.description
		%ExtraInfo.modulate = COLOR_DESCRIPTION
		_tooltip_extra_info = ""
		modulate = Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		EventBus.card_clicked.emit(card_data, self)
