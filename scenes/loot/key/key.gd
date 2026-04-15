# Llave
extends LootPickup

func _on_collected() -> void:
	EventBus.key_collected.emit()
