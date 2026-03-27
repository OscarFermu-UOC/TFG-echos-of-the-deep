# Proyectil del enemigo
extends Area2D

@export var speed: float = 200.0
@export var lifetime: float = 5.0

var has_hit: bool = false # Evita que el proyectil impacte más de una vez
var damage: int
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# Se destruye al agotar su tiempo de vida o al salir de pantalla
	await get_tree().create_timer(lifetime).timeout
	queue_free()
	$VisibleOnScreenNotifier2D.screen_exited.connect(queue_free)

func setup(dir: Vector2, dmg: int) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()

func _physics_process(delta) -> void:
	position += direction * speed * delta

# Colisión con cuerpos físicos (paredes, obstáculos)
func _on_body_entered(_body) -> void:
	_try_destroy()

# Colisión con áreas (hurtbox de player)
func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
		
	if area.has_method("take_damage"):
		area.take_damage(damage)
		set_deferred("monitoring", false)
		_try_destroy()

func _try_destroy() -> void:
	if has_hit:
		return
	has_hit = true
	queue_free()
