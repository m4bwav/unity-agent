# Pixel camera: Pixel Perfect Camera, smooth pans, sharp scaling

Read this when a Unity project draws pixel art or pixel-3D through a low-resolution image and the camera
jitters, the art shimmers, or the window size is not a whole multiple of the art. Settings checked against
Unity's 6000.4 manual page "Pixel Perfect Camera component reference for URP" on 2026-11-19 (R-20261119-1).
The two recipes below are engine-agnostic techniques written for this plugin; they were not run in a Unity
project here, so verify each with a screenshot (rung 4) before calling it done.

## 1. Start with the built-in component (URP 2D Pixel Perfect Camera)

| Property | Use |
|---|---|
| Asset Pixels Per Unit | the PPU every sprite imports with; one value project-wide |
| Reference Resolution | the art's screen size in pixels (for example 320x180) |
| Crop Frame | None, Pillarbox, Letterbox, Windowbox or Stretch Fill. The boxed modes keep a whole-number scale and add bars; Stretch Fill fills the window at a non-integer scale |
| Grid Snapping | Upscale Render Texture (render at reference size, then upscale) or Pixel Snapping (snap sprites to the grid, no texture) |
| Filter Mode | only with Stretch Fill: Retro AA (default, smooths the uneven edges) or Point (sharp, shimmers) |

Rules: whole-number scale with a boxed Crop Frame is the sharpest result; prefer it when bars are acceptable.
Stretch Fill with Retro AA is the built-in answer to non-integer windows, so try it before writing a shader.
Upscale Render Texture also snaps rotation and movement to art pixels, which is the known "jittery camera"
complaint with smooth follow cameras. The component has no sub-pixel camera offset (the manual says nothing
about one in Unity 6000.4); recipe 2 adds it.

## 2. Smooth camera pans over a pixel grid (sub-pixel offset with a bleed margin)

Idea from the Murder engine (isadorasophia/murder, MIT): keep the world on the art grid, but move the final
upscaled image by the leftover fraction of a pixel.

1. Render the world camera into your own RenderTexture of `reference + 2 * bleed` pixels (bleed 2 to 4),
   point filtered, no mipmaps. Do not use the Pixel Perfect Camera's Upscale Render Texture for this camera.
2. Each LateUpdate, after the follow logic: `snapped = floor(target * PPU) / PPU`; place the camera at
   `snapped`; keep `frac = (target - snapped) * PPU` (0 to 1 art pixels per axis).
3. Draw the texture to the screen at `scale` screen pixels per art pixel (a fullscreen blit, a quad in front
   of a second camera, or a UI RawImage), shifted by `-(frac + bleed) * scale` screen pixels. The bleed
   margin covers the edge the shift exposes; the window shows only the inner `reference` area.
4. Snap UI and text separately at screen resolution; they are not part of the low-res texture.

Check: pan the camera slowly in Play Mode and take two screenshots a fraction of a pixel apart; the image
must move by less than one art pixel while each sprite keeps square pixels.

## 3. Sharp-bilinear upscale for non-integer scale

When Stretch Fill's Retro AA is not enough or you blit your own texture (recipe 2): sample with bilinear
filtering, but move the sample to the texel centre except within half a screen pixel of a texel edge. Each
edge gets at most one blended pixel, texels keep even widths, and interiors stay exact. The idea is Cole
Cecil's ("Scaling Pixel Art Without Destroying It", colececil.io, 2017); Murder ships a version of it.

```hlsl
// _MainTex: the low-res texture with Bilinear filtering. _TexSize: its size in texels.
// _Scale: screen pixels per texel (may be fractional, for example 2.5).
float4 SharpBilinear(float2 uv)
{
    float2 t    = uv * _TexSize - 0.5;          // texel space, centres on integers
    float2 base = floor(t);
    float2 f    = t - base;                     // 0..1 between two texel centres
    f = saturate((f - 0.5) * _Scale + 0.5);     // blend only in a band one screen pixel wide
    float2 suv  = (base + 0.5 + f) / _TexSize;
    return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, suv);
}
```

Use it in a URP Full Screen Pass Renderer Feature material or your own blit. Measured on a 24x24 test sprite
at 2.5x: nearest keeps 5 colours but gives uneven 2 and 3 pixel columns; this keeps runs of 1 and 2 pixels
with about 30% of pixels blended, all in one-pixel edge bands; plain bilinear blends 97%.

Related: [3d-models.md](3d-models.md) (the Pixel-3D style row).
