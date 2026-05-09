# Clase base para las pantallas de fin de run: muestra los elementos de UI con fade secuencial.
class_name RevealScreen
extends Control

const SCENE_MAIN_MENU: String = "res://ui/main_menu/main_menu.tscn"

const TITLE_FADE_DURATION: float = 1.0
const TITLE_HOLD: float = 0.5
const PANEL_FADE_DURATION: float = 0.5
const PANEL_HOLD: float = 0.2
const BUTTON_FADE_DURATION: float = 0.5

# Virtual: devuelve los nodos que deben aparecer en secuencia. El último es el botón de confirmar.
func _get_reveal_nodes() -> Array[Node]:
	return []

func _get_confirm_button() -> Button:
	return null

func _ready() -> void:
	var nodes: Array[Node] = _get_reveal_nodes()
	for node in nodes:
		node.modulate.a = 0.0

	var btn: Button = _get_confirm_button()
	if btn:
		btn.disabled = true

	_play_sequence(nodes, btn)

func _play_sequence(nodes: Array[Node], btn: Button) -> void:
	if nodes.is_empty():
		return

	var tween: Tween = create_tween()

	# El primer nodo (título) aparece con una pausa antes del resto
	tween.tween_property(nodes[0], "modulate:a", 1.0, TITLE_FADE_DURATION)
	tween.tween_interval(TITLE_HOLD)

	# Fade in remaining nodes (except the button).
	for i in range(1, nodes.size()):
		tween.tween_property(nodes[i], "modulate:a", 1.0, PANEL_FADE_DURATION).set_trans(Tween.TRANS_QUAD)

	tween.tween_interval(PANEL_HOLD)

	# El botón aparece al final y se habilita al terminar el fade
	if btn:
		tween.tween_property(btn, "modulate:a", 1.0, BUTTON_FADE_DURATION)
		tween.tween_callback(func(): btn.disabled = false)

func _on_btn_menu_pressed() -> void:
	SceneTransition.change_scene_to_file(SCENE_MAIN_MENU)
