# Gestiona los estados del personaje/enemigos, controlando las transiciones entre ellos.
extends Node
class_name StateMachine

@export var initial_state : State

var current_state : State
var states : Dictionary = {} # Diccionario de estados indexados por nombre en minúsculas

func _ready():
	# Esperamos a que el padre esté listo antes de inicializar
	await get_parent().ready
	
	# Registramos todos los estados hijos y conectamos su señal de transición
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.Transitioned.connect(on_child_transition)
	
	if initial_state:
		initial_state.Enter()
		current_state = initial_state
		
func _process(delta):
	if current_state:
		current_state.Update(delta)
	
func _physics_process(delta):
	if current_state:
		current_state.Physics_Update(delta)

# Callback que se ejecuta cuando un estado emite la señal Transitioned
func on_child_transition(state, new_state_name):
	# Ignoramos la transición si no viene del estado activo
	if state != current_state:
		return
	
	var new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	current_state.Exit()
	new_state.Enter()
	current_state = new_state
