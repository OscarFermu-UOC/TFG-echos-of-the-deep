extends Node

# Player-related events
signal player_died
signal noise_made
signal health_changed(current: int, max: int)
signal damage_received(amount: int, pos: Vector2, is_player: bool)

# Enemy-related events
signal enemy_died

# Card-related events
signal card_played(card: CardData)
signal hand_updated(slot_index: int, card: CardData)
signal draw_timer_updated(time_left: float, max_time: float)
