# Gestiona el disparo, la cadencia y la generación de proyectiles del arma equipada.
class_name WeaponSystem
extends Node2D

@onready var muzzle: Marker2D = $Muzzle

# Modificadores aplicables desde objetos o mejoras externas
var damage_bonus: int = 0
var reload_speed_mult: float = 1.0
var crit_chance: float = 0.0

@export var current_weapon: WeaponData
var can_shoot: bool = true

func equip_weapon(data: WeaponData):
	current_weapon = data

func apply_modifiers(dmg_add: int, reload_mult: float, crit: float) -> void:
	damage_bonus = dmg_add
	reload_speed_mult = reload_mult
	crit_chance = crit

func shoot(aim_direction: Vector2):
	if not can_shoot or not current_weapon:
		return
	
	can_shoot = false
	EventBus.noise_made.emit()
	
	# Si el arma tiene varios proyectiles (ej. escopeta), se instancian todos a la vez
	for i in range(current_weapon.projectile_count):
		_spawn_projectile(aim_direction)
	
	# El cooldown se escala con el modificador externo, con un mínimo de 0.1s
	var final_cooldown = current_weapon.cooldown * reload_speed_mult
	final_cooldown = max(0.1, final_cooldown)
	await get_tree().create_timer(final_cooldown).timeout
	can_shoot = true

func _spawn_projectile(dir: Vector2):
	if not current_weapon.projectile_scene: return
	
	var bullet = current_weapon.projectile_scene.instantiate()
	
	# Rotamos la dirección un ángulo aleatorio dentro del rango de dispersión del arma
	var spread_rad = deg_to_rad(current_weapon.spread_degrees)
	var random_angle = randf_range(-spread_rad / 2.0, spread_rad / 2.0)
	var final_dir = dir.rotated(random_angle)
	
	# Comprobamos crítico antes de instanciar para pasarle ya el daño final
	var final_damage = current_weapon.damage + damage_bonus
	var is_crit = randf() < crit_chance
	if is_crit:
		final_damage *= 2
	
	get_tree().root.add_child(bullet)
	bullet.setup(
		muzzle.global_position,
		final_dir,
		current_weapon.projectile_speed,
		final_damage,
		current_weapon.range_lifetime
	)
	
	# Los proyectiles críticos se tiñen de rojo para distinguirlos visualmente
	if is_crit:
		bullet.modulate = Color(1.6, 0.0, 0.25, 1.0)
