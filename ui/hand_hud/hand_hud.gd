# HUD de la mano: crea y actualiza los slots visuales y la barra de progreso de robo.
extends CanvasLayer

const SLOT_COUNT: int = 4

@onready var container: HBoxContainer = %CardsContainer
@onready var global_reload_bar: ProgressBar = %GlobalReloadBar
@onready var card_count_label: Label = %CardCountLabel

@export var slot_scene: PackedScene

var slots_ui: Array = []
var card_manager: CardManager

func _ready():
	card_count_label.text = "0"
	for child in container.get_children():
		child.queue_free()
		
	# Instanciamos los slots y les asignamos su tecla correspondiente
	for i in SLOT_COUNT:
		var slot: Node = slot_scene.instantiate()
		container.add_child(slot)
		slot.setup_key(str(i + 1))
		slots_ui.append(slot)
	
	var run_manager: Node = get_tree().get_first_node_in_group("RunManager")
	if run_manager:
		card_manager = run_manager.card_manager
	
	EventBus.hand_updated.connect(_on_hand_updated)
	EventBus.draw_timer_updated.connect(_on_timer_updated)

func _on_hand_updated(index: int, card: CardData):
	slots_ui[index].set_card(card)
	if card_manager:	
		card_count_label.text = str(card_manager.draw_pile.size())

func _on_timer_updated(time_left: float, max_time: float) -> void:
	if time_left <= 0.0:
		global_reload_bar.value = 0.0
	else:
		# Convertimos el tiempo restante a un porcentaje de progreso para la barra
		global_reload_bar.value = (1.0 - time_left / max_time) * 100.0
