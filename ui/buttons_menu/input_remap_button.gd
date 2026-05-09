# Botón de reasignación de teclas: al pulsarlo escucha la siguiente tecla y la asigna a la acción.
extends Button
class_name InputRemapButton

const TEXT_LISTENING: String  = "..."
const TEXT_UNASSIGNED: String = "Unassigned"

@export var action: String # Nombre de la acción en el InputMap
@export var action_event_index: int = 0 # Índice del evento a reemplazar dentro de la acción

func _ready() -> void:
	toggle_mode = true
	_toggled(false)

func _toggled(toggled_on: bool) -> void:
	if not _action_is_valid():
		return

	if toggled_on:
		text = TEXT_LISTENING
		return

	# Mostramos la tecla asignada actualmente o "Unassigned" si no hay ninguna
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if action_event_index >= events.size():
		text = TEXT_UNASSIGNED
		return

	var input: InputEvent = events[action_event_index]
	if input is InputEventKey:
		var keycode: int = input.physical_keycode if input.physical_keycode != 0 else input.keycode
		text = OS.get_keycode_string(keycode)

func _unhandled_input(event: InputEvent) -> void:
	if not _action_is_valid() or not is_pressed():
		return
	if not (event.is_pressed() and event is InputEventKey):
		return

	# Reemplazamos el binding existente en este índice y añadimos el nuevo
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	if action_event_index < events.size():
		InputMap.action_erase_event(action, events[action_event_index])

	InputMap.action_add_event(action, event)
	action_event_index = InputMap.action_get_events(action).size() - 1

	_cancel_listen()

func _input(event: InputEvent) -> void:
	# Un clic de ratón mientras se escucha cancela la reasignación
	if event is InputEventMouseButton and event.is_pressed():
		_cancel_listen()

# ==========================================================
# HELPERS
# ==========================================================
func _action_is_valid() -> bool:
	return not action.is_empty() and InputMap.has_action(action)

func _cancel_listen() -> void:
	button_pressed = false
	release_focus()
