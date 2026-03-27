# Enemigo a distancia
extends Enemy
class_name EnemyRanged

@export_group("Ranged Setup")

@onready var muzzle: Marker2D = $Muzzle

func _ready() -> void:
	super._ready()

	if stats and not stats.projectile_scene:
		push_warning("EnemyRanged: EnemyStats no tiene projectile_scene asignado.")

	# Se detiene antes de llegar al jugador para poder atacar sin acercarse demasiado
	nav_agent.target_desired_distance = attack_range * 0.8

# Sobreescribe el método virtual de Enemy
func perform_attack() -> void:
	if not stats.projectile_scene or not player:
		return

	var bullet: Node = stats.projectile_scene.instantiate()
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position

	var dir: Vector2 = (player.global_position - muzzle.global_position).normalized()
	bullet.setup(dir, damage)

	if audio_attack and audio_attack.stream:
				audio_attack.pitch_scale = randf_range(0.9, 1.1)
				audio_attack.play()
