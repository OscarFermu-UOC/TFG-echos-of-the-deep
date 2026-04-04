# Slot visual de la mano: muestra una carta y gestiona su animación de aparición.
class_name HandSlot
extends PanelContainer

const HOVER_MODULATE: Color = Color(1.25, 1.25, 1.25) # Brillo al pasar el ratón
const CARD_APPEAR_SCALE: Vector2 = Vector2(1.2, 1.2)
const CARD_APPEAR_DURATION: float = 0.2

@onready var key_label: Label = %KeyBinding
@onready var icon: TextureRect = %Icon

var card_data: CardData

func _ready() -> void:
	_clear_display()

func setup_key(key_text: String):
	key_label.text = key_text

func set_card(card: CardData):
	card_data = card
	
	if card:
		key_label.modulate = Color.WHITE
		icon.texture = card.icon
		icon.modulate = Color.WHITE
		
		# Pequeña animación de escala al robar una carta
		var tween = create_tween()
		scale = CARD_APPEAR_SCALE
		tween.tween_property(self, "scale", Vector2.ONE, CARD_APPEAR_DURATION)
	else:
		_clear_display()
		
func _clear_display() -> void:
	key_label.modulate = Color.DIM_GRAY
	icon.texture = null
	icon.modulate = Color.TRANSPARENT	
