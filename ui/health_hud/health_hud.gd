# HUD de salud: muestra y actualiza los corazones del jugador en pantalla.
extends CanvasLayer

@export var health_per_heart: int = 20 # HP que representa cada corazón completo
@export var heart_scene: PackedScene

@onready var _container: HBoxContainer = $MarginContainer/HeartContainer

const HEART_FULL: int  = 2
const HEART_HALF: int  = 1
const HEART_EMPTY: int = 0

var _hearts: Array[HeartIcon] = []

func _ready() -> void:
	EventBus.health_changed.connect(_on_health_changed)
	
	# Esperamos un frame para que el Player haya terminado su _ready
	await get_tree().process_frame
	_initialize_hearts()

func _initialize_hearts() -> void:
	var player: Player = get_tree().get_first_node_in_group("Player")
	
	if not player:
		return
		
	_setup_max_hearts(player.max_health)
	_update_hearts_display(player.current_health)

func _setup_max_hearts(max_hp: int) -> void:
	for child in _container.get_children():
		child.queue_free()
		
	_hearts.clear()

	var total: int = ceili(float(max_hp) / float(health_per_heart))
	for i in total:
		var heart: HeartIcon = heart_scene.instantiate()
		_container.add_child(heart)
		_hearts.append(heart)

func _on_health_changed(current: int, max_hp: int) -> void:
	# Reconstruimos los corazones si la salud máxima ha cambiado
	if _hearts.size() * health_per_heart != max_hp:
		_setup_max_hearts(max_hp)
		
	_update_hearts_display(current)

func _update_hearts_display(current_hp: int) -> void:
	for i in _hearts.size():
		var heart_min: int = i * health_per_heart
		var heart_mid: int = heart_min + health_per_heart / 2
		var heart_max: int = (i + 1) * health_per_heart

		var state: int
		if current_hp >= heart_max:
			state = HEART_FULL
		elif current_hp >= heart_mid:
			state = HEART_HALF
		elif current_hp > heart_min:
			state = HEART_EMPTY
		else:
			state = HEART_EMPTY

		_hearts[i].update_heart(state)
