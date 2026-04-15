extends Node

# Game-related events
signal game_completed
signal run_successful(data: ArtifactData)
signal artifact_picked_up(data: ArtifactData)
signal artifact_selected
signal compass_target_changed(target_pos)
signal coin_collected
signal key_collected
signal ether_collected
signal key_used
signal stairs_used(type)

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
