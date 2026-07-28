shader_type spatial;

uniform sampler2D albedo_texture : hint_default_white;
uniform sampler2D normal_texture : hint_normal;
uniform vec3 tint_color : hint_color = vec3(1.0);
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform vec3 outline_color : hint_color = vec3(0.0);

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	vec4 albedo = texture(albedo_texture, UV);
	vec3 normal = texture(normal_texture, UV).rgb;
	normal = normalize(normal * 2.0 - 1.0);
	
	vec3 light_dir = normalize(LIGHT);
	float ndotl = max(dot(normal, light_dir), 0.0);
	
	float band = step(0.5, ndotl);
	vec3 lit_color = mix(vec3(0.3), vec3(1.0), band) * tint_color;
	
	ALBEDO = albedo.rgb * lit_color;
	ALPHA = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
