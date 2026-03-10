# Proyectil del jugador: se mueve en línea recta y aplica daño al primer objetivo que toca.
extends Area2D

var has_hit: bool = false # Evita que el proyectil impacte más de una vez
var damage: int
var velocity: Vector2 = Vector2.ZERO
var lifetime: float

func setup(pos: Vector2, dir: Vector2, speed: float, dmg: int, duration: float):
	global_position = pos
	rotation = dir.angle()
	velocity = dir * speed
	damage = dmg
	lifetime = duration
	
	# Se destruye al agotar su tiempo de vida o al salir de pantalla
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func _physics_process(delta):
	position += velocity * delta

# Colisión con cuerpos físicos (paredes, obstáculos)
func _on_body_entered(_body):
	if has_hit: return
	has_hit = true
	queue_free()

# Colisión con áreas (hurtboxes de enemigos)
func _on_area_entered(area: Area2D) -> void:
	if has_hit: return
		
	if area.has_method("take_damage"):
		has_hit = true
		area.take_damage(damage)
		set_deferred("monitoring", false)
		queue_free()
