# Clase base para los objetos recogibles del suelo: gestiona la animación de flotación y la recogida.
class_name LootPickup
extends Area2D

const FLOAT_OFFSET: float = 3.0
const FLOAT_DURATION: float = 1.0
const COLLECT_DURATION: float = 0.2

@onready var _sprite: AnimatedSprite2D = %Sprite2D
@onready var _pickup_sound: AudioStreamPlayer2D = $Audio/PickupSound

func _ready() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(_sprite, "position:y", -FLOAT_OFFSET, FLOAT_DURATION).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "position:y",  FLOAT_OFFSET, FLOAT_DURATION).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	_on_collected()
	
	if _pickup_sound and _pickup_sound.stream:
		_pickup_sound.reparent(get_parent())
		_pickup_sound.play()
	
	# Animación de encogimiento antes de destruir el nodo
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, COLLECT_DURATION).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(queue_free)

# Cada subclase sobreescribe este método para emitir su señal correspondiente
func _on_collected() -> void:
	pass
