# HUD de loot: muestra el contador de monedas y el estado de la llave del dungeon.
extends CanvasLayer

const KEY_LOCKED_COLOR: Color  = Color(0.2, 0.2, 0.2, 0.8)
const KEY_OBTAINED_COLOR: Color = Color(1.0, 0.8, 0.2, 1.0)
const KEY_TWEEN_DURATION: float = 0.3
const POP_SCALE: Vector2 = Vector2(1.5, 1.5)
const POP_IN_DURATION: float = 0.1
const POP_OUT_DURATION: float = 0.2
const STAIRS_KEY_CLEAR_DELAY: float = 0.5 # Pequeño delay antes de ocultar la llave al usar escaleras

@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _coin_label: Label = %CoinLabel
@onready var _key_icon: TextureRect = %KeyIcon

var _loot_manager: LootManager

func _ready() -> void:
	# Esperamos a que el padre esté listo antes de buscar el LootManager
	await get_parent().get_parent().ready
	_loot_manager = get_tree().get_first_node_in_group("LootManager")

	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.key_collected.connect(_on_key_collected)
	EventBus.key_used.connect(_on_key_used)
	EventBus.stairs_used.connect(_on_stairs_used)

	_update_coins()
	_update_key_display(GlobalData.has_dungeon_key)

func _on_coin_collected() -> void:
	_update_coins()
	_play_pop_anim(_coin_icon)

func _update_coins() -> void:
	_coin_label.text = str(_loot_manager.coins) if _loot_manager else "0"

func _on_key_collected() -> void:
	_update_key_display(true)
	_play_pop_anim(_key_icon)

func _on_key_used() -> void:
	_update_key_display(false)

func _on_stairs_used(_type: int) -> void:
	# Al cambiar de planta esperamos un momento antes de resetear el icono
	await get_tree().create_timer(STAIRS_KEY_CLEAR_DELAY).timeout
	_update_key_display(false)

func _update_key_display(is_active: bool) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_key_icon, "modulate", KEY_OBTAINED_COLOR if is_active else KEY_LOCKED_COLOR, KEY_TWEEN_DURATION)

func _play_pop_anim(target: TextureRect) -> void:
	target.pivot_offset = target.size / 2.0
	
	var tween: Tween = create_tween()
	tween.tween_property(target, "scale", POP_SCALE, POP_IN_DURATION).set_trans(Tween.TRANS_BACK)
	tween.tween_property(target, "scale", Vector2.ONE, POP_OUT_DURATION)
