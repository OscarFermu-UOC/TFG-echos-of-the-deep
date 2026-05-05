shader_type canvas_item;

uniform vec4 color : source_color = vec4(0.4, 0.0, 0.0, 1.0); // Rojo sangre
uniform float intensity : hint_range(0.0, 5.0) = 0.0;
uniform float softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Calculamos la distancia desde el centro (UV 0.5, 0.5)
	float dist = distance(UV, vec2(0.5));
	
	// Aplicamos la viñeta
	float vignette = smoothstep(1.0 - softness, 1.0 + softness, dist * intensity);
	
	// Pintamos
	COLOR = vec4(color.rgb, vignette * color.a);
}