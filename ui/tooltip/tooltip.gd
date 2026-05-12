# Tooltip global: sigue al ratón y muestra información de cartas, reliquias u otros recursos.
extends CanvasLayer

const MOUSE_OFFSET: Vector2 = Vector2(15.0, 15.0)
const FADE_DELAY: float = 0.2
const FADE_DURATION: float = 0.5

@onready var _panel: PanelContainer = %TooltipPanel
@onready var _header: Label = %HeaderLabel
@onready var _desc: RichTextLabel = %DescLabel
@onready var _footer: Label = %FooterLabel

var _fade_tween: Tween

func _ready() -> void:
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.modulate.a = 0.0

func _process(_delta: float) -> void:
	if not _panel.visible:
		return
		
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	var pos: Vector2 = mouse_pos + MOUSE_OFFSET

	# Si el panel se sale de pantalla lo recolocamos al lado contrario del cursor
	if pos.x + _panel.size.x > screen_size.x:
		pos.x = mouse_pos.x - _panel.size.x - MOUSE_OFFSET.x
	if pos.y + _panel.size.y > screen_size.y:
		pos.y = mouse_pos.y - _panel.size.y - MOUSE_OFFSET.y

	_panel.position = pos

func show_data(resource: Resource, extra_info: String = "") -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_panel.visible = true
	_panel.modulate.a = 1.0

	_header.text = resource.title if resource.title else "Unknown"
	_desc.text = resource.description.strip_edges()

	if extra_info.is_empty():
		_footer.hide()
	else:
		_footer.text = extra_info.strip_edges()
		_footer.show()

	# Reseteamos el tamaño dos veces para forzar que el panel recalcule su altura
	_panel.size = Vector2.ZERO
	await get_tree().process_frame
	_panel.size = Vector2.ZERO

func hide_tooltip() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_interval(FADE_DELAY)
	_fade_tween.tween_property(_panel, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_callback(_panel.hide)
