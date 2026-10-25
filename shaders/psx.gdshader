// Matériau PS1 : sommets accrochés à une grille d'écran, texture sans filtrage.
// La correction de perspective reste active (pas de gondolage des textures).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
// Taille de la grille d'accrochage des sommets, en « pixels » sur la largeur de l'écran.
// 320 = résolution native ; plus bas = sommets qui tremblent davantage.
uniform float snap_resolution = 320.0;
// Pour les écrans et panneaux lumineux : 0 = éclairé normalement, 1 = auto-éclairé.
uniform float emission_strength : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	if (clip.w > 0.0) {
		vec2 grid = vec2(snap_resolution, snap_resolution * 0.75) * 0.5;
		clip.xy = round(clip.xy / clip.w * grid) / grid * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec3 tex = texture(albedo_texture, UV).rgb * albedo_color.rgb * COLOR.rgb;
	ALBEDO = tex * (1.0 - emission_strength);
	EMISSION = tex * emission_strength;
}
