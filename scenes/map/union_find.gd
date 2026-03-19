# Estructura de datos Union-Find (o Disjoint Set) usada por el algoritmo de Kruskal
# para detectar si dos nodos pertenecen al mismo componente conexo.
class_name UnionFind

var parent: Array[int] = []
var rank: Array[int] = []

func _init(n: int) -> void:
	parent.resize(n)
	rank.resize(n)
	for i in n:
		parent[i] = i # Cada nodo es su propio padre al inicio
		rank[i] = 0

func find(i: int) -> int:
	# Path compression: achatamos el árbol apuntando cada nodo directamente a la raíz
	if parent[i] != i:
		parent[i] = find(parent[i])
	return parent[i]

func union(i: int, j: int) -> bool:
	var root_i: int = find(i)
	var root_j: int = find(j)
	if root_i == root_j:
		return false # Ya pertenecen al mismo componente

	# Union by rank: el árbol más pequeño se cuelga del más grande
	if rank[root_i] < rank[root_j]:
		parent[root_i] = root_j
	elif rank[root_i] > rank[root_j]:
		parent[root_j] = root_i
	else:
		parent[root_j] = root_i
		rank[root_i] += 1
	return true
