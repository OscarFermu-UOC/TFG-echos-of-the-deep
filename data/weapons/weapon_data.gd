# Recurso que define las propiedades visuales y de combate de un arma.
class_name WeaponData
extends Resource

@export_group("Visuals")
@export var name: String = "Pistol"
@export var texture: Texture2D

@export_group("Combat Stats")
@export var damage: int = 10
# Cadencia de tiro
@export var cooldown: float = 0.5
@export var projectile_speed: float = 400.0
# Tiempo en segundos antes de que el proyectil desaparezca
@export var range_lifetime: float = 5.0

@export_group("Shot Mechanics")
# 1 = Pistola, 5 = Escopeta
@export var projectile_count: int = 1
# 0 = Preciso, 30 = Dispersión alta
@export var spread_degrees: float = 0.0
@export var projectile_scene: PackedScene
