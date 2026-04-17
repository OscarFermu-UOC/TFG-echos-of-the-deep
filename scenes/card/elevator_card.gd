# Variante de carta para el Elevator: muestra si está desbloqueada y su coste como "FREE".
class_name ElevatorCard
extends CodexCard

func setup(card: CardData) -> void:
	super.setup(card)
	%ExtraInfo.text = "FREE"
	_tooltip_extra_info = "Unlocked: %s" % str(card.id in GlobalData.save_file.unlocked_card_ids)
