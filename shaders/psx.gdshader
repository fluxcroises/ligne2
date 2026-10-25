// Matériau PS1, repris du prototype navigateur :
// - sommets accrochés à la grille de l'écran (tremblement des polygones) ;
// - éclairage calculé par sommet (Gouraud) : ambiance, soleil, néons du quai, 8 lampes ;
// - brouillard linéaire, textures sans filtrage, sans gondolage.
// Les réglages communs (soleil, brouillard, lampes) sont des paramètres globaux,
// définis dans les réglages du projet et pilotés par le script du lieu.
// Les calculs se font sur des couleurs sRGB, comme dans le prototype.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D albedo_texture : filter_nearest_mipmap, repeat_enable;
uniform vec3 albedo_color = vec3(1.0);
uniform vec3 emission = vec3(0.0);
uniform float unlit = 0.0;
// Seuil de transparence : 0 = opaque, 0,5 pour les grilles et enseignes découpées.
uniform float alpha_cut = 0.0;

global uniform vec2 psx_resolution;
global uniform vec3 sun_dir;
global uniform vec3 sun_color;
global uniform vec3 ambient_color;
global uniform vec3 zone_color;
global uniform vec3 zone_min;
global uniform vec3 zone_max;
// seconde zone éclairée par des néons (salle des billets)
global uniform vec3 zone2_min;
global uniform vec3 zone2_max;
global uniform vec3 fog_color;
global uniform float fog_near;
global uniform float fog_far;
global uniform mat4 lamp_pos_a;
global uniform mat4 lamp_pos_b;
global uniform mat4 lamp_col_a;
global uniform mat4 lamp_col_b;

varying vec3 light;
varying float fog;

vec3 lamp(vec3 wp, vec3 n, vec3 pos, vec3 col) {
	vec3 d = pos - wp;
	float a = clamp(1.0 - length(d) / 7.0, 0.0, 1.0);
	return col * a * a * (0.45 + 0.55 * abs(dot(n, normalize(d))));
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = normalize(mat3(MODEL_MATRIX) * NORMAL);
	vec4 mv = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * mv;
	if (clip.w > 0.0) {
		vec2 grid = psx_resolution * 0.5;
		clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	}
	POSITION = clip;

	float under = smoothstep(-1.6, -0.15, wp.y);  // sous terre : pas de soleil
	vec3 l = ambient_color * (0.22 + 0.78 * under) + sun_color * abs(dot(n, normalize(sun_dir))) * under * 0.8;
	if ((all(greaterThan(wp, zone_min)) && all(lessThan(wp, zone_max)))
			|| (all(greaterThan(wp, zone2_min)) && all(lessThan(wp, zone2_max)))) {
		l += zone_color * (0.6 + 0.4 * abs(n.y));
	}
	for (int i = 0; i < 4; i++) {
		l += lamp(wp, n, lamp_pos_a[i].xyz, lamp_col_a[i].xyz);
		l += lamp(wp, n, lamp_pos_b[i].xyz, lamp_col_b[i].xyz);
	}
	light = mix(l, vec3(1.0), unlit);
	fog = smoothstep(fog_near, fog_far, -mv.z);
}

void fragment() {
	vec4 t = texture(albedo_texture, UV);
	vec3 c = t.rgb * albedo_color * light + emission * t.rgb;
	c = mix(c, fog_color, fog);
	// Godot attend une couleur linéaire et la reconvertit en sRGB à l'affichage.
	ALBEDO = pow(clamp(c, 0.0, 1.0), vec3(2.2));
	ALPHA = t.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
}
