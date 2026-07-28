// Hit-spark flash — billboarded additive quad.
// Deliberately NOT a GPUParticles3D system: Godot 4.4 has an open bug where
// GPUParticles3D billboard mode doesn't rotate correctly (godot#102697), and
// particles are overkill for a single flash. A pooled quad + shader is
// cheaper, mobile-renderer safe, and sidesteps that bug entirely.
//
// Uses the engine's built-in `billboard` render mode rather than a custom
// vertex function — a hand-rolled billboard reconstruction that discards
// MODEL_MATRIX's linear part also discards node.scale, silently breaking
// per-severity sizing. The built-in mode handles camera-facing AND scale.
shader_type spatial;
render_mode unshaded, blend_add, billboard, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D flash_texture : hint_default_white;
uniform float progress : hint_range(0.0, 1.0) = 0.0;   // 0 = spawn, 1 = fully faded

void fragment() {
	vec4 tex = texture(flash_texture, UV);
	float fade = 1.0 - progress;
	ALBEDO = flash_color.rgb;
	ALPHA  = tex.a * flash_color.a * fade * fade;   // fade² = snappy cutoff, not linear droop
}
