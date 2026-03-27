extends Node

# Player-related events
signal player_died
signal noise_made
signal health_changed(current: int, max: int)
signal damage_received(amount: int, pos: Vector2, is_player: bool)

# Enemy-related events
signal enemy_died
