# GUTTERUMBLE Shaders

Custom shaders for GUTTERUMBLE's stylized aesthetic.

## Available Shaders

### cel_shaded.gdshader
Toon-ramp based cell shading with outline. Best for characters.

**Uniforms:**
- `albedo_texture`: Base color map
- `normal_texture`: Normal map
- `tint_color`: RGB tint overlay
- `outline_width`: Edge outline thickness (0.0-0.1)
- `outline_color`: Outline color (default black)

### neon.gdshader
High-contrast with glow emission. For neon signs, UI elements.

**Uniforms:**
- `albedo_texture`: Base color
- `neon_color`: Glow color
- `glow_intensity`: Emission strength (0-10)

## Usage
1. Create MeshInstance3D in scene
2. Create ShaderMaterial on mesh
3. Assign shader to material
4. Configure uniforms in Inspector

## Performance
Target: 30-60fps on mid-range Android (Pixel 6a baseline)
