# Genera el mapa del dungeon proceduralmente: coloca habitaciones, las conecta y pinta el tilemap.
class_name MapGenerator
extends Node2D

# ==========================================================
# CONSTANTES
# ==========================================================
const FLOOR_TERRAIN: int = 0
const TOP_TERRAIN: int   = 1
const FACE_TERRAIN: int  = 2

# Offsets para dar anchura a los pasillos (tile principal + 3 adyacentes)
const CORRIDOR_WIDTH_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)
]

# Las 8 direcciones para detectar vecinos al construir el type_map
const NEIGHBOR_DIRS: Array[Vector2i] = [
	Vector2i( 0, -1), Vector2i( 0,  1), Vector2i(-1,  0), Vector2i( 1,  0),
	Vector2i(-1, -1), Vector2i( 1, -1), Vector2i(-1,  1), Vector2i( 1,  1),
]

const HUNTER_SPAWN_RADIUS: float = 600.0
const COIN_SPAWN_CHANCE: float = 0.5
const INNER_ROOM_MARGIN: int = -1  # Shrinks room by 1 tile to avoid wall overlaps.

enum TileType { NONE, FLOOR, WALL_TOP, WALL_FACE }

# ==========================================================
# EXPORTS
# ==========================================================
@export var tile_map_layer: TileMapLayer
@export var nav_region: NavigationRegion2D

@export_group("Generation")
@export var map_width: int = 80
@export var map_height: int = 50
@export var min_room_size: int = 6
@export var max_room_size: int = 12
@export var room_count: int = 15
# Probabilidad de añadir conexiones adicionales al MST para crear ciclos en el mapa.
@export_range(0.0, 1.0) var loop_probability: float = 0.5

@export_group("Entities")
@export var entities_container: Node2D
@export var target_scene: PackedScene
@export var exit_scene: PackedScene
@export var coin_scene: PackedScene
@export var stairs_down_scene: PackedScene
@export var stairs_up_scene: PackedScene
@export var key_scene: PackedScene
@export var hunter_scene: PackedScene

@export_group("Enemy Spawning")
@export var possible_enemies: Array[EnemySpawnData] = []
@export var base_spawn_chance: float = 0.2
@export var chance_increase_per_stage: float = 0.15

@onready var _player: Player = %Player
# ==========================================================
# ESTADO
# ==========================================================
var rooms: Array[Rect2i] = []
var _spawn_chance: float  = 0.0

# ==========================================================
# API PUBLICA
# ==========================================================
func generate_dungeon(stage: int) -> void:
	if not tile_map_layer:
		push_error("MapGenerator: asgina un TileMapLayer en el inspector.")
		return
	if not tile_map_layer.tile_set:
		push_error("MapGenerator: el TileMapLayer no tiene TileSet asignado.")
		return

	tile_map_layer.clear()
	rooms.clear()
	
	_set_difficulty(stage)
	
	# Si el clank ya alcanzó el umbral invocamos al Hunter antes de generar el nivel
	if GlobalData.max_clank_reached:
		spawn_hunter()

	_place_rooms()

	# Triangulación de Delaunay → MST de Kruskal → añadir ciclos → pintar
	var all_edges: Array = _get_delaunay_edges()
	var mst_edges: Array = _calculate_mst(all_edges)
	var final_edges: Array = _add_loops(mst_edges, all_edges)

	_paint_map(final_edges)

	_spawn_entities()

	if nav_region:
		nav_region.bake_navigation_polygon()

func spawn_hunter() -> void:
	if get_tree().get_first_node_in_group("Hunter"):
		return
		
	var hunter: Node2D = hunter_scene.instantiate()
	hunter.position = _calculate_hunter_spawn_pos()
	entities_container.add_child(hunter)

# ==========================================================
# STEP 0 — DIFFICULTY SCALING
# ==========================================================
func _set_difficulty(stage: int) -> void:
	# El mapa y los enemigos escalan con el stage actual
	map_width  += stage * 10
	map_height += stage * 10
	room_count += stage * 2
	_spawn_chance = clampf(base_spawn_chance + stage * chance_increase_per_stage, 0.0, 1.0)

# ==========================================================
# STEP 1 — ROOM PLACEMENT
# ==========================================================
func _place_rooms() -> void:
	const MAX_RETRIES: int = 100
	for i in room_count:
		for _attempt in MAX_RETRIES:
			var w: int = randi_range(min_room_size, max_room_size)
			var h: int = randi_range(min_room_size, max_room_size)
			var x: int = randi_range(1, map_width  - w - 1)
			var y: int = randi_range(1, map_height - h - 1)
			var new_room := Rect2i(x, y, w, h)

			# grow(1) garantiza al menos 1 tile de separación entre habitaciones
			var overlaps: bool = rooms.any(func(r): return new_room.grow(1).intersects(r))
			if not overlaps:
				rooms.append(new_room)
				break

# ==========================================================
# STEP 2 — DELAUNAY TRIANGULATION
# ==========================================================
func _get_delaunay_edges() -> Array:
	var centers := PackedVector2Array()
	for room in rooms:
		centers.append(room.get_center())

	# Godot devuelve los triángulos como [p0, p1, p2, p0, p1, p2, ...]
	var triangles: PackedInt32Array = Geometry2D.triangulate_delaunay(centers)
	var edges: Array = []

	for i in range(0, triangles.size(), 3):
		var p0: int = triangles[i]
		var p1: int = triangles[i + 1]
		var p2: int = triangles[i + 2]
		edges.append(_make_edge(p0, p1, centers))
		edges.append(_make_edge(p1, p2, centers))
		edges.append(_make_edge(p2, p0, centers))

	return edges

func _make_edge(u: int, v: int, centers: PackedVector2Array) -> Dictionary:
	return { "u": u, "v": v, "dist": centers[u].distance_to(centers[v]) }

# ==========================================================
# STEP 3 — KRUSKAL MINIMUM SPANNING TREE
# ==========================================================
func _calculate_mst(edges: Array) -> Array:
	edges.sort_custom(func(a, b): return a["dist"] < b["dist"])

	var mst: Array = []
	var uf := UnionFind.new(rooms.size())

	# Añadimos la arista si conecta dos componentes distintos (algoritmo de Kruskal)
	for edge in edges:
		if uf.find(edge["u"]) != uf.find(edge["v"]):
			uf.union(edge["u"], edge["v"])
			mst.append(edge)
			edge["is_mst"] = true
		else:
			edge["is_mst"] = false

	return mst

# ==========================================================
# STEP 4 — LOOP ADDITION
# ==========================================================
func _add_loops(mst_edges: Array, all_edges: Array) -> Array:
	# Añadimos aleatoriamente aristas que no forman parte del MST para crear ciclos
	var final_edges: Array = mst_edges.duplicate()
	for edge in all_edges:
		if not edge.get("is_mst", false) and randf() < loop_probability:
			final_edges.append(edge)
	return final_edges

# ==========================================================
# STEP 5 — TILEMAP PAINTING
# ==========================================================
func _paint_map(edges: Array) -> void:
	var floor_cells: Array[Vector2i] = _collect_room_cells()
	floor_cells.append_array(_collect_corridor_cells(edges))

	var type_map: Dictionary = _build_type_map(floor_cells)

	_validate_wall_faces(type_map)

	_flush_to_tilemap(type_map)

func _collect_room_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for room in rooms:
		for x in range(room.position.x, room.end.x):
			for y in range(room.position.y, room.end.y):
				cells.append(Vector2i(x, y))
	return cells

func _collect_corridor_cells(edges: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for edge in edges:
		var start: Vector2 = rooms[edge["u"]].get_center()
		var end:   Vector2 = rooms[edge["v"]].get_center()
		# Pasillo en L: elegimos aleatoriamente si ir primero horizontal o vertical
		var corner: Vector2 = Vector2(end.x, start.y) if randf() > 0.5 else Vector2(start.x, end.y)
		cells.append_array(_get_line_coords(start, corner))
		cells.append_array(_get_line_coords(corner, end))
	return cells

func _build_type_map(floor_cells: Array[Vector2i]) -> Dictionary:
	var type_map: Dictionary = {}

	# Paso 1: marcar suelos
	for cell in floor_cells:
		type_map[cell] = TileType.FLOOR

	# Paso 2: el tile vacío justo al norte de un suelo es la cara del muro
	for cell in floor_cells:
		var north := cell + Vector2i(0, -1)
		if not type_map.has(north):
			type_map[north] = TileType.WALL_FACE

	# Paso 3: cualquier tile vacío adyacente o diagonal a uno existente es la parte superior del muro
	for cell in type_map.keys():
		for dir in NEIGHBOR_DIRS:
			var target: Vector2i = cell + dir
			if not type_map.has(target):
				type_map[target] = TileType.WALL_TOP

	return type_map

func _validate_wall_faces(type_map: Dictionary) -> void:
	# Una WALL_FACE sin WALL_TOP encima se renderizaría mal, así que la convertimos a FLOOR
	var to_fix: Array[Vector2i] = []
	for cell in type_map:
		if type_map[cell] == TileType.WALL_FACE:
			var north: Vector2i = cell + Vector2i(0, -1)
			if not type_map.has(north) or type_map[north] != TileType.WALL_TOP:
				to_fix.append(cell)
	for cell in to_fix:
		type_map[cell] = TileType.FLOOR

func _flush_to_tilemap(type_map: Dictionary) -> void:
	var top_cells: Array[Vector2i] = []
	var face_cells: Array[Vector2i] = []
	var floor_cells: Array[Vector2i] = []

	for cell in type_map:
		match type_map[cell]:
			TileType.FLOOR: floor_cells.append(cell)
			TileType.WALL_FACE: face_cells.append(cell)
			TileType.WALL_TOP: top_cells.append(cell)

	tile_map_layer.clear()
	tile_map_layer.set_cells_terrain_connect(floor_cells, 0, FLOOR_TERRAIN, true)
	tile_map_layer.set_cells_terrain_connect(top_cells, 0, TOP_TERRAIN, true)
	tile_map_layer.set_cells_terrain_connect(face_cells, 0, FACE_TERRAIN, true)
	
# ==========================================================
# STEP 6 — ENTITY SPAWNING
# ==========================================================
func _spawn_entities() -> void:
	if entities_container:
		for child in entities_container.get_children():
			child.queue_free()

	if rooms.is_empty():
		return

	var start_room: Rect2i = rooms[0]
	var exit_room: Rect2i  = _find_farthest_room(start_room)

	var depth: int      = GlobalData.current_depth
	var max_depth: int  = GlobalData.max_depth_for_cycle
	var ascending: bool = GlobalData.is_ascending

	# Al ascender el jugador empieza en la habitación de salida
	_player.position = tile_map_layer.map_to_local(
		exit_room.get_center() if ascending else start_room.get_center()
	)

	# En la planta 1 colocamos la salida; en las demás, escaleras de subida
	if depth == 1:
		_instance_scene(exit_scene, start_room.get_center())
	else:
		_instance_scene(stairs_up_scene, start_room.get_center())

	# En la planta más profunda colocamos el artefacto; si no, escaleras de bajada
	if depth == max_depth:
		_instance_scene(target_scene, exit_room.get_center())
	elif not ascending:
		_instance_scene(stairs_down_scene, exit_room.get_center())

	# Poblamos las habitaciones intermedias con enemigos y monedas
	for room in rooms:
		if room == start_room or room == exit_room:
			continue
		if randf() < _spawn_chance:
			var spawn_data: EnemySpawnData = _pick_random_enemy_by_weight()
			if spawn_data and spawn_data.enemy_scene:
				_instance_scene(spawn_data.enemy_scene, _get_random_pos_in_room(room), spawn_data.stats)
		if randf() < COIN_SPAWN_CHANCE:
			_instance_scene(coin_scene, _get_random_pos_in_room(room))

func _find_farthest_room(origin: Rect2i) -> Rect2i:
	var farthest: Rect2i = origin
	var max_dist: float  = 0.0
	for room in rooms:
		var dist: float = origin.get_center().distance_to(room.get_center())
		if dist > max_dist:
			max_dist = dist
			farthest = room
	return farthest

func _instance_scene(scene: PackedScene, map_coords: Vector2, stats_override: EnemyStats = null) -> void:
	if not scene or not entities_container:
		return
	var instance: Node2D = scene.instantiate()
	if stats_override and instance is Enemy:
		instance.stats = stats_override
	instance.position = tile_map_layer.map_to_local(Vector2i(map_coords))
	entities_container.add_child(instance)

func _calculate_hunter_spawn_pos() -> Vector2:
	# Posición aleatoria en el círculo alrededor del jugador
	var angle: float = randf() * TAU
	return _player.global_position + Vector2(cos(angle), sin(angle)) * HUNTER_SPAWN_RADIUS

func _pick_random_enemy_by_weight() -> EnemySpawnData:
	# Filtramos por ciclo mínimo y hacemos una selección aleatoria ponderada
	var cycle: int = GlobalData.current_cycle
	var candidates: Array = possible_enemies.filter(func(d): return cycle >= d.min_cycle)

	if candidates.is_empty():
		push_warning("MapGenerator: no enemies configured for cycle %d." % cycle)
		return null

	var total_weight: float = 0.0
	for d in candidates:
		total_weight += d.base_weight

	var roll: float      = randf_range(0.0, total_weight)
	var cumulative: float = 0.0
	for d in candidates:
		cumulative += d.base_weight
		if roll <= cumulative:
			return d

	return candidates[0]

# ==========================================================
# HELPERS
# ==========================================================
func _get_line_coords(from: Vector2, to: Vector2) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	var current := Vector2i(from)
	var end := Vector2i(to)
	var x_dir: int = sign(end.x - current.x)
	var y_dir: int = sign(end.y - current.y)

	while current != end:
		coords.append(current)
		# Tiles extra para dar anchura al pasillo; el relleno diagonal evita huecos en esquinas
		for offset in CORRIDOR_WIDTH_OFFSETS:
			coords.append(current + offset)
		if current.x != end.x:
			current.x += x_dir
		elif current.y != end.y:
			current.y += y_dir

	coords.append(end)
	return coords

func _get_random_pos_in_room(room: Rect2i) -> Vector2:
	# grow con valor negativo reduce el área para evitar spawns pegados a las paredes
	var inner: Rect2i = room.grow(INNER_ROOM_MARGIN)
	return Vector2(
		randi_range(inner.position.x, inner.end.x - 1),
		randi_range(inner.position.y, inner.end.y - 1)
	)
