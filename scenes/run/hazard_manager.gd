# Gestiona el nivel de peligro ambiental: sube periódicamente y puede ser bloqueado por cartas.
class_name HazardManager
extends Node
 
@export var max_hazard: int = 100
@export var hazard_interval: float = 5.0 # Segundos entre incrementos automáticos
 
var current_hazard: int = 0
var hazard_block: int = 0
 
var _hazard_timer: Timer
 
func _ready() -> void:
	EventBus.modify_hazard.connect(add_hazard)
 
	_hazard_timer = Timer.new()
	_hazard_timer.wait_time = hazard_interval
	_hazard_timer.autostart = true
	_hazard_timer.one_shot = false
	add_child(_hazard_timer)
	_hazard_timer.timeout.connect(_on_hazard_timer_timeout)
 
func _on_hazard_timer_timeout() -> void:
	add_hazard(1)

func add_hazard(amount: int = 1) -> void:
	# El bloqueo absorbe el peligro entrante antes de que se acumule
	var initial: int = amount
	amount = clampi(amount - hazard_block, 0, amount)
	hazard_block = clampi(hazard_block - initial, 0, hazard_block)
	current_hazard = clampi(current_hazard + amount, 0, max_hazard)

	EventBus.hazard_changed.emit(current_hazard, max_hazard)
	EventBus.hazard_block_changed.emit(hazard_block)
		
func add_hazard_block(amount: int) -> void:
	hazard_block = maxi(hazard_block + amount, 0)
	EventBus.hazard_block_changed.emit(hazard_block)

func reset():
	current_hazard = 0
	hazard_block = 0
	EventBus.hazard_block_changed.emit(0)
