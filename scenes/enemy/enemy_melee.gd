# Enemigo cuerpo a cuerpo
extends Enemy
class_name EnemyMelee

# Tiempo que la hitbox permanece activa tras el golpe
const HITBOX_ACTIVE_DURATION: float = 0.2

@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	super._ready()
	hitbox.monitoring = false

# Sobreescribe el método virtual de Enemy
func perform_attack() -> void:
	hitbox.monitoring = true
	await get_tree().create_timer(HITBOX_ACTIVE_DURATION).timeout
	hitbox.monitoring = false
	
	if audio_attack and audio_attack.stream:
				audio_attack.pitch_scale = randf_range(0.9, 1.1)
				audio_attack.play()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
