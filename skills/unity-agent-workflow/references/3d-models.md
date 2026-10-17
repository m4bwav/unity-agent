# 3D models in a Unity project (the developer's side)

Back to [SKILL.md](../SKILL.md). What a Unity developer, or an agent working in a Unity repo, needs from a 3D
model and how to bring it in so the result is checkable. Sources: [RESEARCH.md](../RESEARCH.md) R-20261017-1
(Unity 6.6 manual, glTFast 6.14 and HDRP 17 docs, read 2026-10-17). [verified] = read in that pass; unmarked =
long-standing practice.

Making, finding, capturing or fixing the mesh itself is the 3D artist's side. When the polywright plugin is
installed, ask it through its asset folder ([contract](https://github.com/m4bwav/polywright/blob/main/skills/polywright/references/contract.md))
with the `game-unity` target; its Unity page ([unity.md](https://github.com/m4bwav/polywright/blob/main/skills/polywright-finish/references/unity.md))
covers Blender export, LOD and collision naming and texture sets from that side. This page starts when a file
lands in `Assets/`.

## Formats and importers

- FBX is Unity's own import chain and its recommended format; `.obj`, `.dae` and `.dxf` also import.
  `.blend`, `.ma`, `.max` and `.c4d` import only when that program is installed on every machine that opens the
  project, so commit an exported `.fbx`, never the `.blend` [verified].
- glTF/GLB needs the Unity glTFast package (`com.unity.cloud.gltfast`, 6.14.1), which registers as the default
  importer for `.gltf` and `.glb`; copy `.bin` and image files with a `.gltf` and keep their relative paths.
  Its editor import does not yet use the default URP/HDRP Lit or Standard materials (it ships its own shaders),
  imports up to eight UV sets but its shaders read two, and its animation imports for the legacy system; Mecanim
  clips need extra work. Draco, KTX2 and meshopt need their companion packages [verified].
- Rule of thumb: FBX for anything rigged, animated or lightmapped; GLB for static props from generators and
  web pipelines, or when the same file also serves three.js.

## Model tab: the settings that matter

| Setting | Set it to | Why [verified unless noted] |
|---|---|---|
| Scale Factor / Convert Units | 1 and on, for metre files | 1 unit = 1 m; a model 100x too big or small is a units mismatch at export, fix it there |
| Bake Axis Conversion | on for Blender FBX not exported with baked axes | otherwise the root carries a -90 X rotation that scripts and prefabs inherit |
| Read/Write | off (default) | on keeps a CPU copy; turn on only for runtime mesh access or non-default MeshCollider cooking |
| Mesh Compression | Off, or Low to Medium for big static props | higher levels lose precision; check seams and thin parts |
| Optimize Mesh | Everything (default) | reorders vertices and triangles for the GPU |
| Generate Colliders | static environment only | adds MeshColliders to every mesh |
| Normals / Tangents | Import; Mikktspace when calculating | match the baker's tangent space or normal maps show seams |
| Generate Lightmap UVs | on when the file has no UV1 and the object is lightmapped | writes `Mesh.uv2` ("UV1"); authored UV1 must sit in 0-1, have margins and no overlaps |
| Generate Mesh LODs (Mesh LOD section) | static props over about 256 triangles | builds LODs at import in the index buffer; see LODs |
| Import Cameras / Lights | off | DCC cameras and lights rarely belong in a game prefab (practice) |
| Materials tab | extract or remap to project materials | embedded materials are read-only and differ per pipeline (practice) |

## Rig and animation

- Rig tab: Humanoid for two legs, two arms and a head with at least 15 bones mapped to the avatar; Generic for
  everything else (vehicles, creatures, doors). Humanoid lets clips retarget between characters [verified].
- Avatar: Create From This Model on the base mesh, Copy From Other Avatar on animation-only files. Fix a bad
  mapping in the Avatar's Configure view, not in the file.
- Skin Weights: Standard (4 bones) unless a deformation needs more. Optimize Game Objects strips the bone
  Transforms (faster); list bones that hold props under Extra Transforms to Expose [verified].
- Animation-only FBX files are named `model@clip.fbx`; Unity's own example postprocessor skips material import
  for paths containing `@` [verified]. Split takes into clips with loop flags on the Animation tab.

## LODs

- LOD Group: name sibling meshes `Name_LOD0`, `Name_LOD1`, ... in one FBX and Unity builds the LOD Group on
  import; LOD0 is the most detailed [verified].
- Mesh LOD (in the manual since Unity 6.2): generated at import, no extra GameObjects, smaller memory than an LOD Group.
  Needs at least 256 triangles; each level has about half the indices; suits organic and dense flat shapes, not
  hard-surface or many-piece meshes. Static batching, particles and VFX Graph always draw LOD0; skinned meshes
  are simplified without regard to weights and still deform LOD0. Cross-fade needs the GPU Resident Drawer
  [verified].

## Materials and texture sets

| Pipeline | Shader | Packed maps |
|---|---|---|
| URP | Lit | Metallic map R = metallic, A = smoothness (Source: Metallic Alpha, the default); occlusion is its own map [verified] |
| HDRP | Lit | mask map R metallic, G occlusion, B detail mask, A smoothness; sRGB off [verified] |
| glTF source | (ORM) | R occlusion, G roughness, B metalness: repack, and smoothness = 1 - roughness |

- Normal maps are OpenGL (Y+); set Texture Type to Normal map. Data maps (mask, metallic, occlusion) have
  sRGB off.
- The Built-in Render Pipeline is deprecated (supported through the Unity 6.7 LTS); new projects pick URP or
  HDRP [verified].

## Draw calls and batching (URP and HDRP, Unity 6.6 guidance)

- Enable the SRP Batcher and the GPU Resident Drawer (Forward+ or Deferred+, compute-capable platforms, Mesh
  Renderers without MaterialPropertyBlocks, at most 128 materials). Leave the per-material GPU Instancing box
  off and static batching off: static batching is incompatible with the GPU Resident Drawer [verified].
- What the model can do for this: few materials per mesh (one to three), shared materials and trim sheets or
  atlases across a kit, one shader variant where possible. The SRP Batcher batches different materials that
  share a shader variant [verified].
- Built-in pipeline projects: static batching (Mesh Renderers only, 64,000 vertices per buffer) and GPU
  Instancing [verified].

## Collision

- Prefer primitives (Box, Sphere, Capsule) and compounds of them on moving objects; a MeshCollider fits static
  level geometry. Convex MeshColliders are limited to 255 triangles and are the only MeshColliders that collide
  with other MeshColliders [verified].
- Ship a simple collision mesh as its own child (for example `Name_Collider`) and assign it in a postprocessor,
  rather than colliding against the render mesh.

## Styles and what each asks of the model

| Style | Model | Textures and shading |
|---|---|---|
| Stylized low-poly | 300 to 5k triangles a prop, flat or hard-edged normals, a palette | one shared gradient or palette atlas, vertex colours; huge batching wins |
| PBR realism | budget by screen size, LODs, baked normals from a high poly | full texture sets (above), consistent texel density, lightmap UV1 for static props |
| Toon (URP) | clean silhouettes, controlled normals (custom normals for faces) | Shader Graph or the Unity Toon Shader package, outlines by inverted hull or a renderer feature |
| Pixel-3D | very low poly, sized to the pixel grid | point filtering, no mipmaps, small textures, a low-resolution render texture upscaled |

## Kits, texel density and naming

- Modular kits: build on a grid (1, 2 or 4 m pieces), pivots on grid corners, so pieces snap with Unity's grid
  and increment snapping. ProBuilder (6.1) blocks out levels before the art exists; Terrain is for large
  natural ground, meshes for everything else.
- Texel density: pick one per project (for example 512 px per metre for first-person desktop) and hold every
  kit piece to it so textures do not jump in sharpness.
- Names: prefix by type (`SM_` static mesh, `SK_` skinned, `M_` material, `T_` texture with `_BaseMap`,
  `_Normal`, `_Mask` suffixes), one folder per asset, so a postprocessor can match on path and suffix.

## Automate imports with an AssetPostprocessor

An `AssetPostprocessor` in an `Editor` folder sets import settings by path or name, so nobody clicks them by
hand and every model in a folder imports the same way. `OnPreprocessModel` changes the `ModelImporter`
(scale, Read/Write, materials, rig); `OnPostprocessModel` edits the result (assign colliders, strip helpers).
Return a new value from `GetVersion()` whenever the code changes, or old assets keep the old settings
[verified]. This is the importer-first rule from Step 3 applied to models.

## Verify an import

Open the asset's Inspector preview or load it in an EditMode test: bounds in metres match the intended size,
the root rotation is zero, triangle and material counts are within the project's budget, normal maps are
flagged Normal, and the Console shows no import warnings. With the Unity CLI and Pipeline, prove it the way
unity-agent-cli describes (load it in `eval` with Play mode stopped) rather than trusting the import log.
