# GUTTERUMBLE Props

Custom modular props for character customization.

## Naming Convention
- `{category}_{name}_{variant}.glb`
- Example: `vest_leather_black.glb`, `weapon_bat_wood.glb`

## Socket Attachment Points
- `headwear`: Head socket
- `torso`: TorsoAttach socket
- `weapons`: Hand_L / Hand_R sockets
- `accessories`: Accessory_Neck, Accessory_Wrist_L/R sockets

## Model Requirements
- Format: GLB (GLTF Binary)
- Embedded textures preferred
- Pivot at origin (0, 0, 0)
- Scale: 1 unit = 1 meter
- Target: <50k triangles per model for Android

## Submission
1. Export from Blender as GLB
2. Test attachment in Character Creator scene
3. Verify socket alignment
4. Add to manifest.json with metadata
