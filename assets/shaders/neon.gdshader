shader_type spatial;

uniform sampler2D albedo_texture : hint_default_white;
uniform vec3 neon_color : hint_color = vec3(1.0, 0.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 2.0;

void fragment() {
	vec4 albedo = texture(albedo_texture, UV);
	ALBEDO = albedo.rgb * neon_color;
	EMISSION = neon_color * glow_intensity;
	ALPHA = albedo.a;
}
