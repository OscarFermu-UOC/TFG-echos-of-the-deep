# Recurso que define las estadísticas y configuración de cada clase de personaje jugable.
class_name CharacterClass
extends Resource

# Identificador único de la clase y datos para el menú de selección
@export var id: String = "scavenger"
@export var char_name: String = "The Scavenger"
@export_multiline var description: String
@export var portrait: Texture2D
@export var unlock_cost: int = 0

# Estadísticas base del personaje
@export_group("Base Stats")
@export var max_health: int = 100
@export var walk_speed: float = 40
@export var run_speed: float = 100.0
@export var acceleration: float = 800.0
@export var friction: float = 1000.0
@export var roll_speed: float = 250.0
@export var roll_duration: float = 0.5
@export var roll_cooldown: float = 0.7
# Distancia a la que el jugador empieza a ser detectado por enemigos
@export var noise_distance_threshold: float = 250

# Equipamiento inicial al comenzar la partida
@export_group("Loadout")
@export var starting_weapon: WeaponData
# var starting_deck: ...
