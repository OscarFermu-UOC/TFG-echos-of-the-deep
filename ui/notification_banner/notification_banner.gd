# Banner de notificación: pausa el juego y muestra un mensaje con icono para eventos importantes.
extends CanvasLayer

const HUNTER_ICON: Texture2D = preload("res://assets/sprites/enemy/hunter.png")
const COLOR_ARTIFACT: Color = Color(1.0, 0.8, 0.2)
const COLOR_HUNTER: Color = Color(1.0, 0.2, 0.2)

const BANNER_IN_DURATION: float = 0.3
const BANNER_OUT_DURATION: float = 0.2
const DIM_ALPHA: float = 0.6 # Opacidad del fondo oscuro durante el banner

@onready var _banner: Control = $Overlay/Banner
@onready var _icon_rect: TextureRect = $Overlay/Banner/MarginContainer/VBoxContainer/Icon
@onready var _label: Label = $Overlay/Banner/MarginContainer/VBoxContainer/MessageLabel
@onready var _dim_bg: ColorRect = $Overlay/DimBackground

func _ready() -> void:
	_banner.scale = Vector2.ZERO
	_dim_bg.modulate.a = 0.0
	hide()

	EventBus.artifact_picked_up.connect(_on_artifact_pickup)
	EventBus.threshold_reached.connect(_on_hunter_spawn)

func show_banner(text: String, icon: Texture2D = null, duration: float = 2.0, color: Color = Color.WHITE) -> void:
	_label.text = text
	_label.modulate = color
	_icon_rect.texture = icon
	_icon_rect.visible = icon != null

	get_tree().paused = true
	show()

	var tween: Tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_banner, "scale", Vector2.ONE, BANNER_IN_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_dim_bg, "modulate:a", DIM_ALPHA, BANNER_IN_DURATION)

	await get_tree().create_timer(duration, true, false, true).timeout
	_hide_banner()

func _hide_banner() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_banner, "scale", Vector2.ZERO, BANNER_OUT_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_dim_bg, "modulate:a", 0.0, BANNER_OUT_DURATION)
	await tween.finished

	hide()
	get_tree().paused = false

func _on_artifact_pickup(_artifact: ArtifactData) -> void:
	show_banner("ARTIFACT ACQUIRED", null, 1.0, COLOR_ARTIFACT)

func _on_hunter_spawn() -> void:
	show_banner("THE HUNTER HAS AWOKEN\nRUN!", HUNTER_ICON, 1.0, COLOR_HUNTER)
