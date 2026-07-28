// Cel / toon shader — arena surfaces and fighters.
// team_color overrides tint_color when set to anything other than white.
// outline_width = 0 disables the vertex-push outline pass for thin geometry.
shader_type spatial;

uniform sampler2D albedo_texture : hint_default_white;
uniform sampler2D normal_texture : hint_normal;
uniform vec3 tint_color : source_color = vec3(1.0);
uniform vec4 team_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);  // alpha 0 = inactive
uniform float outline_width : hint_range(0.0, 0.1) = 0.02;
uniform vec3 outline_color : source_color = vec3(0.0);
uniform float cel_bands : hint_range(1.0, 8.0) = 2.0;
uniform float emissive_strength : hint_range(0.0, 2.0) = 0.0;

void vertex() {
	VERTEX += NORMAL * outline_width;
}

void fragment() {
	vec4 albedo  = texture(albedo_texture, UV);
	vec3 norm    = normalize(texture(normal_texture, UV).rgb * 2.0 - 1.0);
	vec3 light   = normalize(LIGHT);
	float ndotl  = max(dot(norm, light), 0.0);

	// Stepped cel bands
	float band   = floor(ndotl * cel_bands) / cel_bands;
	float shadow = mix(0.25, 1.0, band);

	// Base colour — team_color overrides tint_color when its alpha > 0
	vec3 base    = mix(tint_color, team_color.rgb, team_color.a);
	vec3 lit     = albedo.rgb * base * shadow;

	ALBEDO   = lit;
	EMISSION = base * emissive_strength;
	ALPHA    = albedo.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
