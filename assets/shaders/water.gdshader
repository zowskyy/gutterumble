shader_type spatial;

uniform sampler2D normal_texture : hint_normal;
uniform float wave_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	vec2 uv = UV + TIME * wave_speed * 0.1;
	vec3 normal = texture(normal_texture, uv).rgb;
	NORMAL_MAP = normal;
	
	ALBEDO = vec3(0.1, 0.4, 0.8);
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
}
