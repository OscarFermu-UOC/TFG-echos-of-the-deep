# Base de datos de cartas: proporciona el pool de cartas disponibles y genera las opciones de draft.
extends Node

const MAX_UNIQUE_ATTEMPTS: int = 10 # Intentos máximos para encontrar una carta no repetida

@export var all_cards: Array[CardData] = []

func _ready() -> void:
	if all_cards.is_empty():
		push_warning("CardDatabase: 'all_cards' is empty — no cards will appear.")

func get_draft_options(amount: int = 3, discovery_chance: float = 0.3) -> Array[CardData]:
	var unlocked_ids: Array = GlobalData.save_file.unlocked_card_ids
	
	# Separamos el pool en cartas conocidas (disponibles) y desconocidas (por descubrir)
	var pool_known: Array[CardData] = []
	var pool_unknown: Array[CardData] = []

	for card in all_cards:
		var is_available: bool = card.rarity == CardData.Rarity.COMMON or card.id in unlocked_ids
		if is_available:
			pool_known.append(card)
		else:
			pool_unknown.append(card)

	var result: Array[CardData] = []
	for i in amount:
		var selected: CardData = null

		# Con cierta probabilidad intentamos ofrecer una carta desconocida (descubrimiento)
		if randf() < discovery_chance and not pool_unknown.is_empty():
			selected = _pick_unique(pool_unknown, result)
		# Si no hay descubrimiento o falló, cogemos del pool normal
		if not selected and not pool_known.is_empty():
			selected = _pick_unique(pool_known, result)
		if selected:
			result.append(selected)

	return result

# Devuelve una carta del pool que no esté ya en la selección actual.
# Tras MAX_UNIQUE_ATTEMPTS intentos fallidos devuelve cualquier carta aleatoria.
func _pick_unique(pool: Array[CardData], current_selection: Array[CardData]) -> CardData:
	for i in MAX_UNIQUE_ATTEMPTS:
		var candidate: CardData = pool.pick_random()
		if candidate not in current_selection:
			return candidate
	return pool.pick_random()
