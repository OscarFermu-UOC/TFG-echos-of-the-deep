# Gestiona el ruido generado por el jugador: acumula clank y emite la señal de umbral al llenarse.
class_name ClankManager
extends Node

@onready var _clank_sound: AudioStreamPlayer = $Audio/ClankSound
@onready var _clank_block_sound: AudioStreamPlayer = $Audio/ClankBlockSound

@export var max_clank: int = 10

var current_clank: int = 0
var clank_block: int = 0 # Cantidad de clank que será absorbida antes de acumularse

func _ready() -> void:
	EventBus.noise_made.connect(add_clank)

func add_clank(amount: int = 1) -> void:	
	if amount <= 0:
		return
		
	if _clank_sound and _clank_sound.stream:
		_clank_sound.play()
	
	# El bloqueo absorbe el ruido entrante antes de que se acumule
	var initial_amount = amount
	amount = clampi(amount - clank_block, 0, amount)
	clank_block = clampi(clank_block - initial_amount, 0, clank_block)
	current_clank = clampi(current_clank + amount, 0, max_clank)
	
	EventBus.clank_changed.emit(current_clank, max_clank)
	EventBus.clank_block_changed.emit(clank_block)
	
	# Al llenarse por primera vez invocamos al Hunter
	if current_clank >= max_clank and not GlobalData.max_clank_reached:
		GlobalData.max_clank_reached = true
		EventBus.threshold_reached.emit()
		
func add_clank_block(amount: int) -> void:
	clank_block = maxi(clank_block + amount, 0)
	EventBus.clank_block_changed.emit(clank_block)
	
	if _clank_block_sound and _clank_block_sound.stream:
		_clank_block_sound.play()

func reset():
	current_clank = 0
	clank_block = 0
	GlobalData.max_clank_reached = false
	EventBus.clank_block_changed.emit(0)
