// Post-traitement plein écran : couleurs 15 bits (5 bits par canal) avec tramage de Bayer 4×4.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float color_levels = 32.0;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;

const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	ivec2 p = ivec2(mod(FRAGCOORD.xy, 4.0));
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0 - 0.5;
	float steps = color_levels - 1.0;
	c += threshold * dither_strength / steps;
	c = floor(clamp(c, 0.0, 1.0) * steps + 0.5) / steps;
	COLOR = vec4(c, 1.0);
}
