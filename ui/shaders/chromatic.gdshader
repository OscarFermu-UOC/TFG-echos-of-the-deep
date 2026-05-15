shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float offset : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	vec4 green_channel = texture(screen_texture, SCREEN_UV);
	vec4 red_channel = texture(screen_texture, vec2(SCREEN_UV.x + (offset * SCREEN_PIXEL_SIZE.x), SCREEN_UV.y));
	vec4 blue_channel = texture(screen_texture, vec2(SCREEN_UV.x - (offset * SCREEN_PIXEL_SIZE.x), SCREEN_UV.y));
	
	COLOR = vec4(red_channel.r, green_channel.g, blue_channel.b, 1.0);
}