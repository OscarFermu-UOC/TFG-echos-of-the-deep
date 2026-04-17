# Clase base para las cartas de la UI: aplica estilo de rareza y muestra el tooltip al pasar el ratón.
class_name BaseCard
extends PanelContainer

const HOVER_MODULATE: Color = Color(1.25, 1.25, 1.25)
const COLOR_RARITY_RARE: Color = Color("6699ffff")
const COLOR_RARITY_EPIC: Color = Color("cc66ffff")

@export_group("Rarity Styles")
@export var style_common: StyleBox
@export var style_rare: StyleBox
@export var style_epic: StyleBox

var card_data: CardData
var _tooltip_extra_info: String = ""

# Virtual: las subclases deben llamar a super.setup(card) antes de su propia lógica.
func setup(card: CardData) -> void:
	card_data = card
	%Icon.texture = card.icon
	%Title.text = card.title
	%ExtraInfo.text = ""
	_tooltip_extra_info = ""
	_apply_rarity_style(card.rarity)

func _apply_rarity_style(rarity: CardData.Rarity) -> void:
	var style: StyleBox
	var title_color: Color

	match rarity:
		CardData.Rarity.RARE:
			style = style_rare
			title_color = COLOR_RARITY_RARE
		CardData.Rarity.EPIC:
			style = style_epic
			title_color = COLOR_RARITY_EPIC
		_:
			style = style_common
			title_color = Color.WHITE

	if style:
		add_theme_stylebox_override("panel", style)
	%Title.modulate = title_color
