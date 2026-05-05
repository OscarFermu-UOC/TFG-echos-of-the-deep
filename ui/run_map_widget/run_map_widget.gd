# Widget del mapa de run: genera y muestra el progreso del jugador por ciclos y stages.
extends ScrollContainer

const CYCLE_LABEL_SIZE: int = 16
const NODE_SEPARATION: int = 5
const SEPARATOR_ALPHA: float = 0.2
const ROMAN_NUMERALS: Dictionary = {1: "I", 2: "II", 3: "III", 4: "IV", 5: "V"}

@export var map_node_scene: PackedScene

@export_group("Icons")
@export var icon_combat: Texture2D
@export var icon_sanctuary: Texture2D

var _textures: Dictionary = {}

func _ready() -> void:
	_textures = { "combat": icon_combat, "sanctuary": icon_sanctuary }
	_generate_map()
	await get_tree().process_frame
	_scroll_to_current()

func _generate_map() -> void:
	var main_container: Node = $MainContainer
	for child in main_container.get_children():
		child.queue_free()

	# Calculamos el próximo nodo al que el jugador va a entrar
	var view_cycle: int = GlobalData.current_cycle
	var view_stage: int = GlobalData.current_stage + 1
	
	if view_stage > GlobalData.MAX_STAGES:
		view_stage = 1
		view_cycle += 1

	for c in range(1, GlobalData.MAX_CYCLES + 1):
		var cycle_box := VBoxContainer.new()
		cycle_box.alignment = BoxContainer.ALIGNMENT_CENTER
		main_container.add_child(cycle_box)

		var label := Label.new()
		label.text = _to_roman(c)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", CYCLE_LABEL_SIZE)
		label.modulate = _cycle_label_color(c, view_cycle)
		cycle_box.add_child(label)

		var nodes_box := HBoxContainer.new()
		nodes_box.add_theme_constant_override("separation", NODE_SEPARATION)
		cycle_box.add_child(nodes_box)

		for s in range(1, GlobalData.MAX_STAGES + 1):
			# El último stage de cada ciclo es siempre el santuario
			var node_type: MapNode.Type = MapNode.Type.SANCTUARY if s == GlobalData.MAX_STAGES else MapNode.Type.COMBAT
			var node_status: MapNode.Status = _resolve_status(c, s, view_cycle, view_stage)

			var node_widget: Node = map_node_scene.instantiate()
			nodes_box.add_child(node_widget)
			node_widget.setup(node_type, node_status, _textures)

		# Separador visual entre ciclos
		if c < GlobalData.MAX_CYCLES:
			var sep := VSeparator.new()
			sep.modulate = Color(1.0, 1.0, 1.0, SEPARATOR_ALPHA)
			main_container.add_child(sep)

func _resolve_status(c: int, s: int, view_cycle: int, view_stage: int) -> MapNode.Status:
	if c < view_cycle:
		return MapNode.Status.COMPLETED
	if c > view_cycle:
		return MapNode.Status.FUTURE
	# Mismo ciclo: comparamos por stage
	if s < view_stage:
		return MapNode.Status.COMPLETED
	if s == view_stage:
		return MapNode.Status.CURRENT
		
	return MapNode.Status.FUTURE

func _cycle_label_color(c: int, view_cycle: int) -> Color:
	if c < view_cycle:  return Color.GRAY
	if c == view_cycle: return Color.YELLOW
	return Color.DARK_GRAY

func _scroll_to_current() -> void:
	# Calculamos el porcentaje de progreso total para centrar el scroll en el nodo actual
	var total_progress: int = (GlobalData.current_cycle - 1) * GlobalData.MAX_STAGES + GlobalData.current_stage
	var total_nodes: int = GlobalData.MAX_CYCLES * GlobalData.MAX_STAGES
	var percentage: float = float(total_progress) / float(total_nodes)
	scroll_horizontal = int(percentage * (get_child(0).size.x - size.x))

func _to_roman(number: int) -> String:
	return ROMAN_NUMERALS.get(number, str(number))
