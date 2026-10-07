# Learnings: unity-agent-cli

Procedural lessons for [SKILL.md](SKILL.md). Research findings live in [RESEARCH.md](RESEARCH.md); every change is logged in [CHANGELOG.md](CHANGELOG.md); test runs in [TESTS.md](TESTS.md); state in `evergreen.json`. Format and write-time gate: MAINTENANCE.md (LEARNINGS-FORMAT). Retired entries go to LEARNINGS-ARCHIVE.md with a reason.

Write an entry the moment a real signal happens: a user correction, the same error twice, a discovered workaround, an environment fact, a stated preference, a failed test or a failure in use. Check existing entries first (add / update / retire / none). Trigger and Hypothesis are required. Promote after three confirmations; retire when harmful > helpful.

## Active

### L-001 · 2026-09-06 · A freshly installed `unity` is not on the PATH of the shell that installed it
- Trigger: right after the install script finished (2026-09-06), `unity --version` failed in the same PowerShell tool session; `"$env:LOCALAPPDATA\Unity\bin\unity.exe" --version` worked.
- Hypothesis: the installer edits the user PATH in the registry and broadcasts the change; a running process keeps its environment snapshot.
- Rule: call the binary by full path in the installing session (the probe script does this and says so in `notes`); tell the user new terminals will have `unity` on PATH.
- Evidence: C-20260906-1 (SKILL.md §Step 1, scripts/unity_probe.ps1)
- Scope: global
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-002 · 2026-09-06 · Installing the Pipeline package is a repo and Editor mutation; ask first
- Trigger: while building this skill the Editor of a Unity 6 game project was open and `pipeline list` showed no package; installing it would have edited the tracked `Packages/manifest.json` and forced a domain reload in the user's session without their say.
- Hypothesis: the CLI's own skill and Unity's docs both say to request permission because the change is visible in git and interrupts the Editor.
- Rule: never run `unity pipeline install` unasked; report `hasPipelinePackage: false` and offer the one command.
- Evidence: SKILL.md §Step 2 route table; Unity-Technologies/skills unity-cli SKILL.md
- Scope: skill
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-003 · 2026-09-06 · A manifest change is resolved only when the user really focuses the Editor
- Trigger: after `unity pipeline install` (2026-09-06) the Editor sat with the package in `Packages/manifest.json` but nothing in `Library/PackageCache` for 20 minutes; `WScript.Shell.AppActivate` and P/Invoke `SetForegroundWindow`/`ShowWindow` from the agent shell changed nothing, and the first user click (while the game was in Play mode) also did nothing; the second click after stopping Play triggered the resolve and domain reload within seconds.
- Hypothesis: Unity re-reads the manifest on a genuine window-activation event and defers package resolution while in Play mode; focus stolen by a background process is ignored by Windows.
- Rule: after any manifest change while the Editor is open, tell the user in one line to stop Play mode and click into the Editor window, and wait for `Library/Pipeline/.unity-pipeline-port` (or `unity status` ready) before running live commands; do not try to focus the window programmatically.
- Evidence: R-20260906-5; C-20260906-3
- Scope: global
- Status: promoted (C-20260906-3) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-004 · 2026-09-15 · Only `capture_game_view --source screen` (Play Mode) shows UI Toolkit; `screenshot` and `--source camera` are camera-only
- Trigger: a Unity 6 game project (UI Toolkit runtime UI, Unity 6000.6.0f1, pipeline 0.6.0-exp.1) on 2026-09-15: `screenshot --view game` and `capture_game_view --source camera` of a mid-game frame showed terrain and sprites and no HUD; the same frame with `--source screen` showed the full HUD, hand and overlay.
- Hypothesis: both camera paths render `Camera.main` into a RenderTexture and UIDocument panels do not render through a camera; `source=screen` reads the composited Game view backbuffer, which only exists at runtime (Edit Mode returns "requires Play Mode"; `-nographics` throws "No GPU available").
- Rule: for any UI check use `capture_game_view --source screen --width W --height H --save_path <folder>~/x.png` in Play Mode; `save_path` is confined to the `Assets/` authoring root (a tilde folder avoids the import and the `.meta`). Reserve `screenshot` for Edit Mode world-only captures.
- Evidence: package `Documentation~/commands/capture.md`; `Editor/Commands/Capture/CaptureCommands.cs`; live PNGs 2026-09-15 (recorded in the game project's own solution notes)
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-09-15

### L-005 · 2026-09-15 · The player loop freezes while the Editor is unfocused; captures silently return a stale frame
- Trigger: same session, Play Mode entered via `editor_play` from the agent shell: `Time.frameCount` stayed at 90076 for minutes whenever the terminal had focus, the game's own ready flag never flipped, and `capture_game_view` returned a plausible old frame with no error while `editor_status` still said `playing`. `set_autotick` (pumps `EditorApplication.update` only), `editor_focus` and `QueuePlayerLoopUpdate` did not help.
- Hypothesis: the project has Player Settings Run In Background off, so Unity stops the player loop when the Editor is not the foreground app, and no CLI command changes that.
- Rule: right after `editor_play`, run `unity command eval --code "UnityEngine.Application.runInBackground = true; return 1;"` (runtime only, resets when Play Mode ends, touches nothing on disk) and, before any capture, confirm `Time.frameCount` differs between two evals. Do not flip the project setting; it changes shipped-player behaviour and is the user's call.
- Evidence: live run 2026-09-15 (frames resumed immediately after the eval)
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-09-15

### L-006 · 2026-09-16 · `editor_play` is silently dropped when it lands right after `open_scene` or `editor_stop`
- Trigger: the same game project, 2026-09-15: the CLI answered "Entered play mode" but `editor_status.playMode` stayed `stopped` for 120 s when `editor_play` followed `open_scene` at once; reproduced by hand after `editor_stop`; the same command 30 s later worked first time.
- Hypothesis: the Editor is still busy with the previous request and the `isPlaying` assignment is lost in that window.
- Rule: settle about 3 s after `open_scene`/`editor_stop`, then issue `editor_play` and poll `editor_status` for up to 20 s; if it never flips, re-issue `editor_play` (up to 4 tries) rather than waiting longer.
- Evidence: the game project's snapshot script (retry loop), multi-scenario runs 2026-09-16
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-09-16

### L-007 · 2026-09-16 · Files edited on disk are not imported before Play Mode unless you refresh
- Trigger: 2026-09-15: a tinted USS stylesheet produced a pixel-identical capture through the CLI; after `unity command eval --code "UnityEditor.AssetDatabase.Refresh(); return 1;"` the same edit showed up.
- Hypothesis: Unity imports changed files on Editor focus or an explicit refresh; a CLI-driven Editor never regains focus.
- Rule: after editing USS/UXML/scripts/assets from a shell, eval `AssetDatabase.Refresh()` (or `recompile` for C#) and wait for `editor_status` to leave `compiling` before `editor_play` or a capture.
- Evidence: the preflight step of the game project's snapshot script
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-09-16


### L-008 · 2026-09-28 · `unity open` through a pipe never returns; start it with Start-Process and --non-interactive
- Trigger: 2026-09-28: a PowerShell script ran `& unity open <path> --format json 2>&1 | Out-String` on a self-hosted CI runner; the Editor opened and went idle, the script blocked for over an hour with no CPU and no child process.
- Hypothesis: the pipe read ends only when every writer closes it, and the Editor that `unity open` launches inherits the write end. `Start-Process` with `-RedirectStandard*` leaks it too (.NET inherits all inheritable handles when redirecting). Plain `Start-Process` does not leak, but the CLI then has an interactive console and waits on a prompt nobody sees unless given `--non-interactive`.
- Rule: from any script that captures CLI output, open the Editor with `Start-Process <unity.exe> -ArgumentList open,"<path>",--no-banner,--non-interactive -PassThru` (no redirection, default window style so the Editor is not minimized), then poll `unity status` for `ready`. Verified: CLI exits code 0 in under 1 s, Editor ready about 20 s later on a warm Library.
- Evidence: the game project's ai-docs/solutions/2026-09-28-unity-open-from-a-piped-script-hangs-forever.md (timing table)
- Scope: global
- Update 2026-10-04: counter-observation. In a Claude Code PowerShell tool call on a Windows 11 workstation (CLI 1.0.0-beta.12, Editor 6000.6.4f1), `unity open "<path>" --no-banner 2>&1 | Select -Last 5; unity status --until-ready --timeout 600 --format json` returned with the Editor ready. One run, not a retraction: keep the Start-Process rule for scripts and CI, and note whether a piped open hangs next time before relaxing it.
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-09-28

### L-009 · 2026-10-04 · PowerShell breaks `\"` inside `unity command eval --code`; use Bash single quotes and one eval for a whole batch
- Trigger: 2026-10-04, wiring art onto seven card assets in a game project: a PowerShell loop ran `unity command eval --code "return Wiring.Wire(\`"$k\`", ...);"` once per card; all seven failed with `COMPILATION_FAILED: Unexpected character '\' (line 1, col 38)` / "Newline in constant". The same C# from the Bash tool in single quotes (`--code 'var o=""; foreach (var k in new[]{"a","b"}) o += Wire(k, k, false); return o;'`) succeeded first time and wired all seven in one call.
- Hypothesis: PowerShell 7's native-argument passing re-quotes the string and keeps the backslashes, so the Editor's Roslyn sees `\"` as source text. Bash passes single-quoted text unchanged.
- Rule: send any eval whose C# contains string literals from Bash with single quotes, not from PowerShell. Loop inside the C# (one eval, one round trip, one JSON result) instead of one eval per item: fewer tool calls and a single envelope to read.
- Evidence: a private game project's card-art skill (seven assets wired by one eval, 2026-10-04)
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-10-04

### L-010 · 2026-10-06 · `set-import-settings-ignores-unknown-keys`: `set_import_settings` reports success while skipping keys it does not know
- Trigger: 2026-10-06, CLI 1.0.0-beta.12 with Pipeline 0.6.0-exp.1 on Unity 6000.6.4f1: `unity command set_import_settings -- --asset <png> --settings '{"textureType":"Sprite",...,"bogusKey":1}' --dry_run true` returned `success: true` with `applied` listing the six real keys and `unknown: ["bogusKey"]`. A settlement game's building-sprite workflow sets its sprites this way (Single mode, 48 PPU, Point filter, no mipmaps, alpha is transparency).
- Hypothesis: the command maps each key onto an `AssetImporter` property by name and collects the misses instead of failing, so a misspelled key (`pixelsPerUnit` for `spritePixelsPerUnit`) leaves the asset unchanged behind a green envelope.
- Rule: send the settings once with `--dry_run true`, stop if `unknown` is non-empty, then send them for real and read the result back with `get_import_settings`. The command takes no `--confirm`; it re-imports the asset on a real run.
- Evidence: live dry run and `get_import_settings` 2026-10-06 (nothing written); command schema from `unity command --format json`; R-20261006-2
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-10-06

### L-011 · 2026-10-06 · `prove-import-by-loading`: an asset is imported when the Editor can load it, not when its file and .meta exist
- Trigger: a settlement game's production-sound workflow (seen 2026-10-06) writes a `.wav`, refreshes the AssetDatabase through `eval`, and confirms the import with `Resources.Load<AudioClip>(...)` and its `length`, stopping Play mode first. Checked here the same day: the eval returned `400.056` for a real clip and, for a wrong path, `success: true` with a null clip.
- Hypothesis: a file plus a .meta on disk says nothing about whether the importer accepted it (an unsupported format, a broken hand-written .meta, or an import still pending all look the same from the shell), and the Editor defers imports while in Play mode.
- Rule: after a shell-side asset change, refresh (L-007), check `editor_status` shows `playMode: stopped` (send `editor_stop` if not), then load the asset in one eval and return a property only a real import has (`AudioClip.length`, `Texture2D.width`, a sprite count); test for null yourself, because a missing asset does not fail the eval.
- Evidence: live evals 2026-10-06 (read only); R-20261006-2
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-10-06
