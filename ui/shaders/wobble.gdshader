shader_type canvas_item;

uniform float strength : hint_range(0.0, 5.0) = 0.5;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float frequency : hint_range(0.0, 10.0) = 2.5;

void vertex() {
	// Movemos los vértices (Efecto gelatina)
	VERTEX.x += sin(TIME * speed + VERTEX.y * frequency) * strength;
	VERTEX.y += cos(TIME * speed + VERTEX.x * frequency) * strength;
}