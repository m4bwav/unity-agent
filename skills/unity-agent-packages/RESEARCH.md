# Research: unity-agent-packages

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: Unity Package Manager from the command line and scripts: manifest.json, Client API headless pattern, Pipeline package commands, OpenUPM, AI-related Unity packages and version traps. Tier `moderate`. Last refresh 2026-09-06; next due 2026-10-06.

## Current understanding

- The Unity CLI has no package command of its own; Unity's official `unity-package-management` skill drives `UnityEditor.PackageManager.Client` from `-executeMethod` with a poll-and-`EditorApplication.Exit` pattern and warns that `unity run` (which injects `-quit`) cannot be used because `Client.Add` completes on later Editor ticks.
- With `com.unity.pipeline` on a running Editor, `package_add`, `package_remove`, `package_resolve` and `package_status` are registered commands (async, poll status).
- Hand-editing `Packages/manifest.json` is officially documented (6000.3 Manual "Edit the package manifest"); `packages-lock.json` is regenerated on resolve. OpenUPM needs a scoped registry block; openupm-cli 4.5.x (May 2026) writes it.
- Version traps: `com.unity.ai.assistant` 2.13.0-pre.2 on 6000.5.1f1 livelocks the AssetDatabase (UUM-132096); Assistant packages need Unity Cloud; Unity Test Framework 2.0 changes batchmode behaviour; code coverage needs `com.unity.testtools.codecoverage`.
- The manifest of a Unity 6 game project (2026-09-06): test-framework 1.7.0, URP 17.5.0, inputsystem 1.19.0, no AI or pipeline packages.

## Open questions

- Which `com.unity.ai.assistant` version fixes UUM-132096 on 6000.5.
- Does the Pipeline `package_add` accept git URLs and scoped-registry packages.
- Does Unity plan a `unity package` CLI command (would supersede the Client API script).

- Is `package_add`'s parameter `--name` or `--identifier` on Pipeline 0.8, and what does 0.9 rename it to (R-20261011-1)?

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `docs.unity3d.com/<version>/Documentation/Manual/cus-edit-manifest.html`; `docs.unity3d.com/ScriptReference/PackageManager.Client.html`
- `docs.unity3d.com/Packages/com.unity.ai.assistant@<latest>/changelog`; `UUM-132096`

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- github.com/Unity-Technologies/skills/tree/main/skills/unity-package-management (commits); `openupm.com/blog`; `path:SKILL.md "manifest.json" unity`
- `unity package cli command <year>` (watch for an official command)

Practice (how others use AI agents on this goal, and everything in between):

- `site:discussions.unity.com "manifest.json" agent OR "claude code" <year>`

Testing (how the job is verified and what checkers exist):

- `unity upm.log error resolve package ci <year>`; `"packages-lock.json" ci unity`

Best sources (primary first): docs.unity3d.com Manual and ScriptReference, the official skill's SKILL.md, openupm.com. Noisy: random blog posts on manifest hacks.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20261011-1 · 2026-10-11 · Subject and tooling: Pipeline 0.8 and the 0.9 renames, `package_add --identifier`, UTF core package, MSBuild NuGet, package signing
- Summary: `com.unity.pipeline` is at 0.8.0-exp.1 (not 0.4.x); 0.9.0 renames many commands with no aliases (2026-10-07 notice). Unity's `unity-pipeline` skill (2026-10-08) uses `unity command package_add --identifier <id> --confirm true` and names commands absent from 0.8's changelog, so it probably targets 0.9; the parameter name on 0.8 needs checking with `unity command --format json`. Test Framework is a core package fixed to the Editor (1.9 on 6.7; 2.0 abandoned). Assistant 2.20.0-pre.2 (2026-10-02) has no changelog entry for UUM-132096, so the trap stands. 6.7 MSBuild mode allows `<PackageReference>` under a policy (MSBU0006, MSBU0007). Unity 6.3+ verifies package signatures; OpenUPM serves signed tarballs; UnityNuGet signed since May 2026 (a stale cache can fail the check). Unity's `unity-package-management` skill has 6,155 installs, unchanged since 2026-09-06. Practice and testing quiet.
- Track: subject, tooling
- Sources: https://packages.unity.com/com.unity.pipeline, https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-pipeline/SKILL.md, https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559, https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.20/changelog/CHANGELOG.html, https://docs.unity.com/en-us/engine/6000.7/manual/programming-environment/script-compilation/msbuild/unity.md, https://openupm.com/blog/unitynuget-packages-are-now-code-signed/, https://skills.sh/api/search?q=unity
- Magnitude: 0.45 (the Pipeline route's parameter and version claims were stale)
- Applied: C-20261011-1 (SKILL.md Step 2 Pipeline row; Step 5 bullets)

### R-20260906-2 · 2026-09-06 · Version traps for AI packages on Unity 6.5
- Summary: CoplayDev #1219 documents the Assistant 2.13-pre livelock on 6000.5.1f1 (UUM-132096); workaround is removing the package, deleting packages-lock.json and Library. Applied as a trap in Step 5.
- Track: practice
- Sources: https://github.com/CoplayDev/unity-mcp/issues/1219
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Official package-management skill and manifest docs
- Summary: Unity-Technologies/skills `unity-package-management` (Client API script, no `-quit`, `-logFile -`, verification via manifest), Unity Manual manifest editing, openupm-cli May 2026 improvements. The installer script is vendored under `references/` with attribution.
- Track: tooling
- Sources: https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-package-management/SKILL.md, https://docs.unity3d.com/6000.3/Documentation/Manual/cus-edit-manifest.html, https://openupm.com/blog/openupm-recent-improvements-may-2026/
- Magnitude: n/a (initial)
- Applied: C-20260906-1
