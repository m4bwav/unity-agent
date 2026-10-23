# Research: unity-agent-workflow

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: how AI coding agents work safely in Unity projects: verification ladder, YAML and .meta rules, Humble Object testing, agent skill packs for Unity, Unity's AI policies and agent roadmap. Tier `moderate`. Last refresh 2026-09-06; next due 2026-10-06.

## Current understanding

- Practitioner consensus in 2026 (Unity Discussions threads including Unity-MCP maintainers): code-only agent work is the most reliable; generate editor scripts rather than emit `.unity`/`.prefab` YAML (token-hungry, unreliable); UI layout stays fragile; asset-index files and naming conventions help agents.
- Verification: engine-free NUnit projects that link `Assets/**/*.cs` (with a `UnityEngine` stub, or against `UnityEngine.CoreModule.dll`) are a documented mainstream pattern (gamedev.center 2026-03); `dotnet build` on the Unity-generated csproj is a whole-assembly compile check; Unity Test Framework via `unity test` or `-runTests`; live checks via Pipeline `recompile`, `get_console_logs`, `screenshot`, `eval`. Research prototypes (arXiv 2603.07101, 2608.25518, GameDevBench 2602.11103) verify generated Unity code by compile plus scripted replay and state assertions; none is a drop-in harness.
- Skill packs: Unity-Technologies/skills (official, MIT, ~730 stars, 13-14 skills, `npx skills add`), nowsprinting/unity-coding-skills (test-first; Rider MCP dependency; successor to the archived claude-code-settings-for-unity), Nice-Wolf-Studio/unity-claude-skills (35 skills, WHEN/WRONG/RIGHT/GOTCHA), gamedev-skills/awesome-gamedev-agent-skills (67 skills, router), Besty0728/Unity-Skills (in-Editor installer). No Unity entry in github/awesome-copilot; cursor.directory Unity rules are generic C# style.
- Unity roadmap: Unity CLI + Pipeline (July 2026) is the official agent path; `unity mcp` replaces the Assistant MCP; Unity 6.6 defaults Fast Enter Play Mode; Unity 7 preview Dec 2026, release Q1 2027, positioned around agent collaboration; CoreCLR migration (6.7+) may affect bridges.
- Policy: Unity ToS updated 2026-06-30 (automated tools act under the account holder's responsibility); Asset Store allows AI-generated content with disclosure and bans training on Store assets (2025-08-06); Unity AI Guiding Principles page exists. Nothing restricts a hobby project.
- This skill's repo-independent rules were written against the AGENTS.md of a Unity 6 game project (Humble Object, importer-first, .meta handling, save-data risk), which already encodes them.

## Open questions

- Which skill pack, if any, gains real install counts on skills.sh (only Unity-Technologies shows numbers so far).
- Does Unity publish agent-facing guidance (an `llms.txt`, an "AI in Unity" manual page) beyond the CLI skill?
- Does Fast Enter Play Mode by default (6.6) change the domain-reload rule for agents?

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `unity.com/blog agents OR "ai agents" editor <month year>`; `unite <year> keynote recap ai`
- `unity.com/legal` and `support.unity.com` "AI" policy pages (diff against the last refresh)

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `path:SKILL.md unity` on GitHub code search sorted by recently updated; `npx skills find unity`; skills.sh unity; github.com/Unity-Technologies/skills commits; nowsprinting/unity-coding-skills releases
- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; `awesome-copilot unity`; cursor.directory unity

Practice (how others use AI agents on this goal, and everything in between):

- `site:discussions.unity.com "claude code" OR cursor OR codex workflow <year>`; hn.algolia.com `unity "claude code"` by date; r/Unity3D `agent` with a date filter
- `"unity" agent "yaml" prefab scene generate editor script <year>`

Testing (how the job is verified and what checkers exist):

- `site:arxiv.org unity agent verification replay <year>`; `GameDevBench`; `unity humble object dotnet test <year>`
- `unity test framework play mode screenshot diff agent <year>`

Best sources (primary first): unity.com/blog, discussions.unity.com (dated threads), the skill repos on GitHub, arXiv cs.SE. Noisy: Medium (403), YouTube, generic "AI game dev" listicles.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20261023-1 · 2026-10-23 · Subject: Cinemachine 3 component names, scripting define symbols, game-design rules for the new reference
- Summary: Cinemachine 3 moved to the `Unity.Cinemachine` namespace and added new component types with clearer names (the docs say they are new types, not renames): `CinemachineCamera` (was `CinemachineVirtualCamera`), `CinemachineFollow` (Transposer), `CinemachinePositionComposer` (Framing Transposer), `CinemachineRotationComposer` (Composer), `CinemachineDeoccluder` (Collider), `CinemachineConfiner2D` and `CinemachineConfiner3D` (Confiner), `CinemachineThirdPersonFollow` (3rdPersonFollow); true renames are only `CinemachineThirdPersonAim` and `CinemachineSequencerCamera` (was BlendListCamera). 3.1.5 is the release listed for Unity 6.2. Custom scripting symbols: a `csc.rsp` in Assets, Player Settings > Other Settings > Script Compilation > Scripting Define Symbols (Apply), or Build Profiles > Build Data > Scripting Defines; `PlayerSettings.SetScriptingDefineSymbols` takes effect after a recompile. `DEVELOPMENT_BUILD` is a built-in symbol for players built with Development Build; `Debug.isDebugBuild` is the runtime check. Design rules from Rogers, *Level Up!* 3rd ed. (Levels 4-13 and 19, Bonus Levels 1-5), restated in this skill's own words; the numbers in them are the book's rules of thumb, marked heuristic. The page's two C# blocks compile against the Unity 6000.6.6f1 Editor's UnityEngine, Physics, NUnit and TestRunner assemblies (C# 9).
- Track: subject
- Sources: https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/whats-new.html, https://docs.unity3d.com/Packages/com.unity.cinemachine@3.1/manual/CinemachineUpgradeFrom2.html, https://docs.unity3d.com/Manual/com.unity.cinemachine.html, https://docs.unity3d.com/6000.2/Documentation/Manual/custom-scripting-symbols.html, https://docs.unity3d.com/6000.2/Documentation/Manual/scripting-symbol-reference.html; Rogers, *Level Up!* (reading notes kept outside the repository)
- Magnitude: minor (new reference)
- Applied: C-20261023-1 (references/game-design.md, SKILL.md Step 4)
### R-20261017-1 · 2026-10-17 · Subject: importing 3D models into Unity 6.6 (import settings, LOD, texture packing, batching, collision)
- Summary: the unversioned manual is Unity 6.6 (built 2026-10-16). FBX is Unity's import chain; `.blend`, `.ma`, `.max`, `.c4d` import only with the program installed. Model tab: Read/Write off by default, Optimize Mesh Everything by default, Mesh Compression Off to High, Bake Axis Conversion, Generate Lightmap UVs writes `Mesh.uv2` ("UV1"), authored lightmap UVs in 0-1 with margins and no overlaps; a Mesh LOD section (generated at import into the index buffer, at least 256 triangles, about half per level; static batching, particles and VFX Graph draw LOD0; skinned meshes simplified without regard to weights; cross-fade needs the GPU Resident Drawer). LOD Group from `_LOD0.._LODn` names. Rig: Humanoid needs at least 15 bones; Standard 4 bone weights; Optimize Game Objects. Convex MeshColliders are limited to 255 triangles. URP Lit smoothness from the Metallic map alpha by default; HDRP mask map R metallic, G occlusion, B detail mask, A smoothness, sRGB off. Draw calls in URP/HDRP: enable the SRP Batcher and the GPU Resident Drawer, disable per-material GPU Instancing and static batching (incompatible with the GPU Resident Drawer); the Built-in pipeline is deprecated, supported through 6.7 LTS. glTFast 6.14.1 (`com.unity.cloud.gltfast`) is the default `.gltf`/`.glb` importer; its editor import does not yet use the default Lit or Standard materials; two UV sets in its shaders; Draco, KTX2 and meshopt via companion packages. `OnPreprocessModel` with `GetVersion()` for import automation. ProBuilder docs at 6.1.
- Track: subject
- Sources: https://docs.unity3d.com/Manual/3D-formats.html, https://docs.unity3d.com/6000.2/Documentation/Manual/FBXImporter-Model.html, https://docs.unity3d.com/Manual/LightingGiUvs-GeneratingLightmappingUVs.html, https://docs.unity3d.com/Manual/lod/mesh-lod-introduction.html, https://docs.unity3d.com/Manual/lod/mesh-lod-generator.html, https://docs.unity3d.com/6000.2/Documentation/Manual/importing-lod-meshes.html, https://docs.unity3d.com/6000.2/Documentation/Manual/FBXImporter-Rig.html, https://docs.unity3d.com/Manual/ConfiguringtheAvatar.html, https://docs.unity3d.com/Manual/class-MeshCollider.html, https://docs.unity3d.com/Manual/urp/lit-shader.html, https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@17.2/manual/Mask-Map-and-Detail-Map.html, https://docs.unity3d.com/Manual/optimizing-draw-calls-choose-method.html, https://docs.unity3d.com/Manual/urp/gpu-resident-drawer.html, https://docs.unity3d.com/Manual/static-batching.html, https://docs.unity3d.com/Manual/SRPBatcher.html, https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.14/manual/features.html, https://docs.unity3d.com/Packages/com.unity.cloud.gltfast@6.14/manual/ImportEditor.html, https://docs.unity3d.com/ScriptReference/AssetPostprocessor.OnPreprocessModel.html
- Magnitude: minor (new reference)
- Applied: C-20261017-2 (references/3d-models.md)

### R-20261011-1 · 2026-10-11 · Subject, tooling, practice, testing: ToS agentic-access clauses, Unity 7 alpha, skill-pack adoption, Unity Insight
- Summary: the 2026-06-30 Terms section 17.2 (ff) and (gg) limit AI agents and MCP clients to "Authorized Agentic Access" that Unity runs or designates, revocable; Unity's support account (informal, Reddit) says this covers cloud services, the Asset Store and online APIs, and local Editor use is fine; no official FAQ. Unity 7 public alpha (2026-10-05; preview December, release early 2027): CoreCLR only, code reloads instead of domain reloads, text-serialized assets start with a `%UNITY` format-version directive that older Editors refuse; MSBuild compilation experimental in 6.7. Skill packs: Unity-Technologies/skills `unity-cli` 7,286 installs (about 5.8K on 2026-09-22), 1,063 stars, `unity-pipeline` and 2D skills added 2026-10-08, no outside PRs; gamedev-skills 74 skills, about 3.5K installs each, 1,419 stars; Nice-Wolf 20 skills. Practice: arXiv 2609.27585 "Unity Insight" (a code-and-asset index through `.meta` GUIDs) cut tokens 53% and time 52% on 28 questions (one run each; code unreleased). Testing: GameDevBench is Godot only; no Unity agent benchmark.
- Track: subject, tooling, practice, testing
- Sources: https://roboin.io/article/en/2026/07/02/unity-denies-concerns-over-ban-on-third-party-ai/, https://discussions.unity.com/t/unity-7-0-alpha-is-now-available/1738310, https://unity.com/releases/editor/alpha/7000.0.0a7, https://skills.sh/api/search?q=unity, https://github.com/Unity-Technologies/skills/commits/main, https://arxiv.org/abs/2609.27585, https://arxiv.org/pdf/2609.23142
- Magnitude: 0.35
- Applied: C-20261011-1 (SKILL.md Step 4 pointers and roadmap; Step 5 terms)

### R-20260906-4 · 2026-09-06 · Practice: agent test hygiene from a no-experience Unity project (r/ClaudeAI thread)
- Summary: A widely upvoted r/ClaudeAI post (2026-09-06, "Day 5 of making a cozy game", Unity via Claude Desktop, no dev background) and its comments. The OP's process matches this skill's ladder: small scoped updates, git rollback for every change, a ~150-item check pass after each change with screenshots as evidence, and the human re-checking the screenshots. Two cautions from an experienced commenter were the actionable part: an agent told "add tests" produces tautological tests that catch nothing, and when tests break the agent tends to call them "pre-existing" so red tests accumulate and get ignored. Added as a Step 2 rule. The OP's model mix, costs, and 3D pipeline (Gemini images, Meshy, Blender scripts) are self-reported and not relevant to a verification skill; not recorded.
- Track: practice
- Sources: an r/ClaudeAI post and a reply from an experienced commenter, 2026-09-06 (thread text supplied by the user; not fetched)
- Magnitude: 0.2
- Applied: C-20260906-2

### R-20260906-3 · 2026-09-06 · Verification research and headless-test practice
- Summary: gamedev.center pattern for linking Unity sources into a .NET NUnit project; Unity Discussions on Humble Object; arXiv replay/verification papers and GameDevBench. Applied as the ladder and the "not a drop-in harness" note.
- Track: testing
- Sources: https://gamedev.center/run-unity-tests-faster-dotnet/, https://discussions.unity.com/t/humble-object-pattern-unit-testing-compatibility-vs-integration-test-compatibility/606262, https://arxiv.org/abs/2603.07101, https://arxiv.org/html/2608.25518, https://arxiv.org/html/2602.11103v2
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-2 · 2026-09-06 · Skill packs for Unity agents, ranked
- Summary: Unity-Technologies/skills, nowsprinting/unity-coding-skills (and the archived predecessor), Nice-Wolf-Studio, gamedev-skills, Besty0728, The1Studio. No awesome-copilot Unity entry. Applied as the pointers section.
- Track: tooling
- Sources: https://github.com/Unity-Technologies/skills, https://github.com/nowsprinting/unity-coding-skills, https://github.com/nowsprinting/claude-code-settings-for-unity, https://github.com/Nice-Wolf-Studio/unity-claude-skills, https://github.com/gamedev-skills/awesome-gamedev-agent-skills, https://github.com/Besty0728/Unity-Skills
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Practitioner consensus, Unity roadmap, and AI policy
- Summary: Unity Discussions threads on CLI/MCP/agent workflows (YAML emission unreliable; editor scripts win); Unite Seoul 2026 recap (6.6 Fast Enter Play Mode default, Unity 7 timeline); ToS 2026-06-30 and Asset Store AI policy.
- Track: practice
- Sources: https://discussions.unity.com/t/cli-mcp-ai-ide-chatgpt-codex-cursor-antigravity-claude-code-windsurf-next-steps-for-unity-workflow-automation/1705679, https://discussions.unity.com/t/i-made-a-reference-doc-to-help-ai-agents-claude-cursor-use-the-unity-cli-mcp/1733846, https://unity.com/blog/unite-seoul-keynote-2026-recap, https://unity.com/legal, https://support.unity.com/hc/en-us/articles/16456407029524
- Magnitude: n/a (initial)
- Applied: C-20260906-1
