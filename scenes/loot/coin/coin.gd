# Moneda de oro
extends LootPickup

func _on_collected() -> void:
	EventBus.coin_collected.emit()
