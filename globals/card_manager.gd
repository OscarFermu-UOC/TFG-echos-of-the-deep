# Gestiona el mazo de cartas del jugador: robo, descarte, mano y el temporizador de robo.
class_name CardManager
extends Node

# DEBUG:
@export var debug_deck: Array[CardData]

# ==========================================================
# CONSTANTS
# ==========================================================
const MIN_COOLDOWN_MULT: float = 0.5 # Límite inferior del multiplicador de velocidad de robo
const DRAW_TIMER_CLEAR: Vector2 = Vector2(0.0, 1.0) # Valores para resetear el timer en la UI

# ==========================================================
# EXPORTS
# ==========================================================
@export var hand_size: int = 4
@export var base_draw_interval: float = 5.0 # Segundos entre robos

# ==========================================================
# STATE
# ==========================================================
var draw_pile: Array[CardData] = []
var discard_pile: Array[CardData] = []
var hand: Array[CardData] = [] 

var draw_timer: float = 0.0
var is_drawing: bool = false
var current_max_time: float = 5.0 # Intervalo real tras aplicar modificadores

var cooldown_mult: float = 1.0 # Modificador de velocidad de robo (aplicado por upgrades)

# ==========================================================
# CICLO DE VIDA
# ==========================================================
func _ready() -> void:
	hand.resize(hand_size)
	hand.fill(null) # La mano empieza con todos los slots vacíos
	
	# DEBUG:
	start_deck_cycle(debug_deck)

func _process(delta: float) -> void:
	if not is_drawing:
		return
	draw_timer -= delta
	EventBus.draw_timer_updated.emit(draw_timer, current_max_time)
	if draw_timer <= 0.0:
		_finish_draw_cycle()

# ==========================================================
# INPUT
# ==========================================================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_card_1"): _try_play_slot(0)
	if event.is_action_pressed("use_card_2"): _try_play_slot(1)
	if event.is_action_pressed("use_card_3"): _try_play_slot(2)
	if event.is_action_pressed("use_card_4"): _try_play_slot(3)

# ==========================================================
# API PUBLICA
# ==========================================================
func start_deck_cycle(initial_deck: Array[CardData]) -> void:
	draw_pile = initial_deck.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
 
	for i in hand_size:
		_draw_single_card()
 
	is_drawing = false
	draw_timer = 0.0
 
func force_draw(amount: int) -> void:
	for i in amount:
		if not _draw_single_card():
			push_warning("CardManager: could not draw (hand full or deck empty).")
			break

# ==========================================================
# DRAW CYCLE
# ==========================================================
func _try_play_slot(index: int) -> void:
	var card: CardData = hand[index]
	if card == null:
		return
	
	EventBus.card_played.emit(card)
	discard_pile.append(card)
	
	hand[index] = null
	EventBus.hand_updated.emit(index, null) 
	
	# Si al jugar una carta queda algún slot libre, activamos el temporizador de robo
	_check_draw_state()
	
func _check_draw_state() -> void:
	if not is_drawing and _has_empty_slots():
		_start_draw_timer()
		
func _start_draw_timer() -> void:
	is_drawing = true
	current_max_time = base_draw_interval * cooldown_mult
	draw_timer = current_max_time
	
func _finish_draw_cycle() -> void:
	if not _draw_single_card():
		# No se pudo robar (mazo vacío y descarte también), detenemos el ciclo
		is_drawing = false
		EventBus.draw_timer_updated.emit(DRAW_TIMER_CLEAR.x, DRAW_TIMER_CLEAR.y)
		return
 
	if _has_empty_slots():
		_start_draw_timer() # Quedan huecos, seguimos robando
	else:
		is_drawing = false
		EventBus.draw_timer_updated.emit(DRAW_TIMER_CLEAR.x, DRAW_TIMER_CLEAR.y)
	
# ==========================================================
# HELPERS
# ==========================================================
func _has_empty_slots() -> bool:
	return hand.has(null)

func _draw_single_card() -> bool:
	if draw_pile.is_empty():
		return false
 
	var empty_index: int = hand.find(null)
	if empty_index == -1:
		return false
 
	var new_card: CardData = draw_pile.pop_back()
	hand[empty_index] = new_card
	EventBus.hand_updated.emit(empty_index, new_card)
	return true

func _reshuffle_deck() -> void:
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	draw_pile.shuffle()
