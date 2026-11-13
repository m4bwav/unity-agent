# Performance: measure, classify, then fix one thing

Read this when a Unity task is about frame rate, hitches, memory or "make it faster". Origin: Unity's two free
Unity 6 e-books, *Ultimate guide to profiling Unity games* and *Optimize your game performance for consoles and
PCs*; every API, marker and counter name below was checked against Unity's 6000.3 docs (R-20261113-1), and the
capture route was run once on Unity 6000.3 (R-20261113-2). Model import settings and batching live in
[3d-models.md](3d-models.md); this file does not repeat them.

## Procedure

1. Budget. Target frame rate and device give the budget in ms: 1000 / fps (16.66 ms at 60, 33.33 ms at 30).
   Mobile targets leave about a third of the frame idle against thermal throttling (book rule). Ask for the
   target when the task does not state it.
2. Baseline. Capture a repeatable run (a scripted path, a fixed scene, a replay) before changing anything,
   from a development player on the target when the number will be reported; Editor numbers are for finding,
   not for reporting.
3. Classify with the marker table below: in budget, main thread, render thread, worker threads or GPU. Only
   the slowest thread or chip is worth work.
4. Fix the largest item in that class, one change at a time. The traps list gives suspects; a grep hit in code
   that runs once is not a finding.
5. Capture the same run again and compare the median frame (typical cost) and the longest frame (the hitch).
   A frame-rate average hides hitches; compare in ms.
6. Deep profiling only as a second pass to find where, never how much: it inflates call-heavy code. Allocation
   call stacks (Profiler toolbar, Call Stacks) are cheaper and come first.
7. Memory last: GC Allocated In Frame should read 0 on gameplay frames; diff two Memory Profiler snapshots
   around a scene load and unload to find survivors.

A performance claim names the budget, the device, the build type (Editor or development player), and a before
and after number from the same run.

## Getting numbers an agent can read

- `ProfilerRecorder` (Unity.Profiling) reads counters and markers from a script, in the Editor and in players:
  `ProfilerRecorder.StartNew(ProfilerCategory category, string statName, int capacity = 1)`, read `LastValue`
  or `GetSample(i)` for `i < Count`, and `Dispose()` in `OnDisable`. Write the values to a text file under
  `Logs/` or to the log, then read the file. This fits the state-dump recipe in SKILL.md Step 2.
- `FrameTimingManager.CaptureFrameTimings()` each frame, then `GetLatestTimings(count, FrameTiming[])`
  gives CPU, main, render and GPU frame times in ms. Always on in development players; release players need
  Player > Frame Timing Stats (`enableFrameTimingStats` in ProjectSettings.asset).
- Counter names that returned values in the run (`Main Thread` is from the `ProfilerRecorder` page's example,
  the rest from the counters reference): `Main Thread`, `CPU Main Thread Frame Time`,
  `CPU Render Thread Frame Time`, `CPU Total Frame Time`, `GPU Frame Time` (Internal, nanoseconds);
  `GC Allocated In Frame` (not available in release players), `GC Reserved Memory`, `System Used Memory`,
  `Total Reserved Memory` (Memory, bytes); `Draw Calls Count`, `Batches Count`, `SetPass Calls Count`,
  `Triangles Count`, `Vertices Count` (Render).
- What the run showed (R-20261113-2): a player started with `-batchmode` renders nothing, so render-thread,
  GPU and draw-call counters read 0; measure rendering in a windowed development player. `Count` stayed near
  30 for a 150-frame run with capacity 120, so average over `Count`, not `Capacity`. Quitting from inside
  `Update` logs harmless "Missing Profiler.EndSample" lines.
- Performance Testing package (`com.unity.test-framework.performance`, 3.7.0): `[Test, Performance]` or
  `[UnityTest, Performance]` tests with `Measure.Frames()`, `Measure.Method(...)`,
  `Measure.ProfilerMarkers(...)`, `Measure.Custom(...)`; it extends the Unity Test Framework, so it runs on
  ladder rung 3 and asks first like any new package.
- A `.raw` file from `-profiler-log-file` is for a person to open in the Profiler window (and pull into
  Profile Analyzer); the agent's numbers come from the routes above. Third-party raw-to-CSV converters are
  not assumed installed. Flags: unity-agent-headless Step 3.

## Marker table

Names as printed on Unity's markers reference (6000.3). Read them in the CPU module's Timeline or a saved
capture; marker names vary a little by platform.

| Class | Main thread shows | Render thread shows | Next |
|---|---|---|---|
| In budget | `WaitForTargetFPS` pads the end of the frame (`Application.targetFrameRate` set) | `Gfx.WaitForCommands` (idle) | done with frame time; check memory |
| Main-thread bound | no wait marker; time in `BehaviourUpdate`, `PreLateUpdate.ScriptRunBehaviourLateUpdate`, `FixedBehaviourUpdate`, `GC.Alloc` | `Gfx.WaitForCommands` | scripts, physics, allocations, cameras, UI, animation |
| Render-thread bound | `Gfx.WaitForPresentOnGfxThread` | busy in `Camera.Render` | batching, camera count, culling |
| Worker-bound | long `WaitForJobGroupID` | | jobs scheduled too late, not Burst-compiled, or not parallel |
| GPU-bound | `Gfx.WaitForPresentOnGfxThread` | waits in `Gfx.PresentFrame` | post effects, overdraw, resolution, shader cost, dense meshes |

- Several `FixedBehaviourUpdate` samples in one frame mean several physics steps: a slow frame causes extra
  steps, which slow the next frame. Settings: `Fixed Timestep` and `Maximum Allowed Timestep`.
- `GC.Alloc` samples carry a size, not a real duration; count bytes, then wrap the code in a
  `ProfilerMarker` to time it.
- `Profiler.CollectGlobalStats` is the cost of the enabled Profiler modules; keep only the modules you need.

## Traps to grep for

Look inside `Update`, `LateUpdate`, `FixedUpdate` and code they call unless noted. A hit is a lead until a capture
shows it. Replacements are Unity 6000.3 APIs (R-20261113-1).

| Pattern | Why | Replace with |
|---|---|---|
| `.tag ==`, `.tag.Equals(` | allocates a string | `CompareTag(string)` |
| `Camera.main` per frame | cost comparable to `GetComponent` (docs) | cache it in a field |
| `GetComponent<`, `GameObject.Find` per frame | lookup every call | cache in `Awake` or `Start` |
| `new WaitForSeconds(` inside a coroutine loop | new object every pass | one cached instance |
| `new List<`, `new Dictionary<`, `new ...[]`, LINQ, `Regex`, string `+` or `$"` per frame | managed allocations | a field cleared and reused, `StringBuilder` |
| `SetFloat("`, `SetBool("`, `SetTrigger("` and other string-keyed property calls | hashes the name each call | `Animator.StringToHash`, `Shader.PropertyToID` and the `int` overloads |
| `.material` on a Renderer read for its values (anywhere) | creates a per-renderer copy and breaks batching | `Renderer.sharedMaterial` |
| `.position =` then `.rotation =` on one Transform | two transform updates | `Transform.SetPositionAndRotation` |
| `Instantiate(` then a parent assignment | reparent after creation | `Instantiate(original, position, rotation, parent)` |
| `Instantiate(`/`Destroy(` churn in spawn or fire code | allocation and GC | `UnityEngine.Pool.ObjectPool<T>` |
| `Physics.OverlapSphere(`, `Physics.RaycastAll(` | return new arrays ("Allocates memory", docs) | `Physics.OverlapSphereNonAlloc`, `Physics.RaycastNonAlloc` with a preallocated buffer |
| `Physics.Raycast(` in a loop over many agents | one call each on the main thread | `RaycastCommand.ScheduleBatch` |
| `MeshCollider` added to a generated mesh at runtime | cooking on the main thread | `Physics.BakeMesh(EntityId, bool)` first, can run in a job |
| `OnCollisionStay` with Reuse Collision Callbacks off | a new `Collision` per call | `Physics.reuseCollisionCallbacks = true` (`m_ReuseCollisionCallbacks`) |
| Empty `Update` or `LateUpdate` (anywhere) | still a native-to-managed call | delete it |
| `Debug.Log` in per-frame code | string building and log I/O | wrap in a `[System.Diagnostics.Conditional("SYMBOL")]` method |
| `GC.Collect` outside menus, pauses or loads | a full stop of the game | collect at hidden moments only |
| More than one enabled `Camera` outside split-screen | each pays culling and setup | one camera plus renderer features |

Physics transforms: leave Auto Sync Transforms off (`m_AutoSyncTransforms: 0`) and call `Physics.SyncTransforms()`
before a query that needs moved transforms.

## Settings to read

Keys read from a Unity 6000.3 project's files (the default new project unless noted). Read them; change them
through the Editor or an editor script, never by hand while an Editor holds the project.

| Setting | File | Key (default seen) | Read it as |
|---|---|---|---|
| VSync Count per quality level | ProjectSettings/QualitySettings.asset | `vSyncCount: 0` (one per level; `m_CurrentQuality` picks the level) | 0 (Don't Sync) for readable captures; restore for release |
| Texture upload buffer (MB) | QualitySettings.asset | `asyncUploadBufferSize: 16` | near the largest texture loaded |
| Mipmap streaming | QualitySettings.asset | `streamingMipmapsActive: 0` | on with per-texture `streamingMipmaps` |
| MSAA (Built-in) | QualitySettings.asset | `antiAliasing: 0` | URP and HDRP set it on the pipeline asset |
| Fixed Timestep | ProjectSettings/TimeManager.asset | `Fixed Timestep: 0.02` (read in an existing project) | 50 Hz; extra steps per frame mean trouble |
| Maximum Allowed Timestep | TimeManager.asset | `Maximum Allowed Timestep: 0.33333334` | lower caps the catch-up loop |
| Auto Sync Transforms | ProjectSettings/DynamicsManager.asset | `m_AutoSyncTransforms: 0` | keep 0 |
| Reuse Collision Callbacks | DynamicsManager.asset | `m_ReuseCollisionCallbacks: 1` | keep 1 |
| BroadPhase Type | DynamicsManager.asset | `m_BroadphaseType: 0` (Sweep and Prune) | box pruning for large flat worlds |
| Default solver iterations | DynamicsManager.asset | `m_DefaultSolverIterations: 6` | raise per body, not globally |
| Frame Timing Stats | ProjectSettings/ProjectSettings.asset | `enableFrameTimingStats: 0` | 1 if release players need FrameTimingManager |
| Static and dynamic batching | ProjectSettings.asset | `m_BuildTargetBatching` entries with `m_StaticBatching`, `m_DynamicBatching` (an existing project: Standalone 1 and 0) | static off with the GPU Resident Drawer (below) |
| Graphics APIs | ProjectSettings.asset | `m_BuildTargetGraphicsAPIs` (empty list = automatic) | remove unused APIs to cut variants |
| Scripting backend | ProjectSettings.asset | `scriptingBackend` map per platform (empty = default) | IL2CPP for release and profiling |
| Log stack traces | ProjectSettings.asset | `m_StackTraceTypes` (one value per log type) | trim for release builds that log |
| Prebake Collision Meshes | ProjectSettings.asset | `bakeCollisionMeshes: 0` | on when meshes get colliders at load |
| Mesh data | ProjectSettings.asset | `StripUnusedMeshComponents`, `VertexChannelCompressionMask` | Optimize Mesh Data and Vertex Compression |
| Scripting define symbols | ProjectSettings.asset | `scriptingDefineSymbols` map | log symbols absent in release |
| Asset serialization | ProjectSettings/EditorSettings.asset | `m_SerializationMode: 2` (Force Text) | required for the YAML rules in SKILL.md |
| Always Included Shaders | ProjectSettings/GraphicsSettings.asset | `m_AlwaysIncludedShaders` | remove unused shaders |
| BatchRendererGroup variants | GraphicsSettings.asset | `m_BrgStripping: 0` | Keep All for the GPU Resident Drawer |
| URP batching and GPU Resident Drawer | the URP asset (a project's `Assets/Settings/*.asset`) | `m_UseSRPBatcher`, `m_SupportsDynamicBatching`, `m_GPUResidentDrawerMode`, `m_GPUResidentDrawerEnableOcclusionCullingInCameras`, `m_MSAA`, `m_UpscalingFilter` | see 3d-models.md |

Not found in the files read, so no key is printed here: Graphics Jobs mode. Check it in Player > Other
Settings.

## Import settings to read

`.meta` files, read-only; change them through the importer, `set_import_settings`, or an `AssetPostprocessor`
(3d-models.md). Model keys are in 3d-models.md.

- Texture (`*.png.meta` and the like, `TextureImporter`): `isReadable` (on doubles memory), `enableMipMap` (off
  for UI and sprites, on for 3D), `streamingMipmaps`, `maxTextureSize`, `textureType`, and one
  `platformSettings` block per `buildTarget` (`DefaultTexturePlatform`, `Standalone`, ...) with its own
  `maxTextureSize`, `textureFormat` and `textureCompression`.
- Audio (`*.wav.meta`, `AudioImporter`): `forceToMono` (on for spatialized sounds), `loadInBackground`,
  `preloadAudioData`, and in the sample settings `loadType`, `compressionFormat`, `quality`,
  `sampleRateSetting`. Music and loop decisions belong to musicwright-game when it is installed.

## Where the books disagree, and what this file keeps

- Project Auditor: one book calls it experimental, the other a package from 6.1. Docs: `com.unity.project-auditor`
  3.2.0 supports 6000.0 and later, and from Unity 6.4 it ships with the Editor (Window > Analysis > Project
  Auditor). Kept the docs.
- Frame Debugger: one book says it does not show single draw calls. Docs: it lists the frame's rendering
  events, and its Batch cause field says why the SRP Batcher could not batch an event with the previous one. It
  has no timings. Kept the docs.
- Build Settings against Build Profiles: Development Build and Deep Profiling are options in the Unity 6 Build
  Profiles window (Deep Profiling only with Development Build). Kept Build Profiles.
- Static batching beside the GPU Resident Drawer: the books list both. The plugin's verified line stands and the
  GPU Resident Drawer page agrees: turn Static Batching off in Player > Other Settings when using it.
- Mobile budgets with a third left idle are mobile thermal advice only; desktop and console use the full frame.
- Incremental GC and the Boehm collector notes are Unity 6 runtime facts and may change with Unity 7's CoreCLR.
