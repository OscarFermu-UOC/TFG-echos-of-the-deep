# Éter
extends LootPickup

func _on_collected() -> void:
	EventBus.ether_collected.emit()
