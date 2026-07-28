// Flat team-colour shader for fighters.
// Set team_color per-instance via material_override on the MeshInstance3D.
// Emissive glow drives readability in dark arena lighting.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 team_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float emissive_strength : hint_range(0.0, 3.0) = 0.6;
uniform float rim_power : hint_range(0.0, 8.0) = 3.0;

void fragment() {
	// Rim light — brightens edges facing away from camera for silhouette pop
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);
	vec3 lit = team_color.rgb + rim * team_color.rgb * emissive_strength;
	ALBEDO   = lit;
	EMISSION = team_color.rgb * emissive_strength * 0.4;
	ALPHA    = team_color.a;
}
