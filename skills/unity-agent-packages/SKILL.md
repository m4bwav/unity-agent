---
name: unity-agent-packages
description: "Add, remove, pin, upgrade, or look up Unity Package Manager (UPM) packages from outside the Editor UI: editing Packages/manifest.json safely, the Unity Package Manager Client API run headless (the async poll pattern without -quit), the Pipeline package_add/package_remove commands on a running Editor, OpenUPM and git-URL packages, packages-lock.json, and which AI-related Unity packages are safe on which Unity version. Use whenever the user asks to install or remove a Unity package, add com.unity.something, bump a package version, fix a package resolution error, add an OpenUPM or GitHub package, or says 'refresh unity-agent-packages' / 'is unity-agent-packages stale'. General CLI use is unity-agent-cli; batchmode mechanics are unity-agent-headless."
---

# Unity packages (UPM from the command line and scripts)

Outcome: the package change is applied through a route that resolves dependencies (Editor
API, Pipeline command, or a reviewed manifest edit) and is proven by `Packages/manifest.json`
plus a successful resolve (no `upm.log` errors, Editor out of Safe Mode).

## Step 0: freshness (every use, one read)

Read `evergreen.json` next to this file. If `verify_at_use` is true, re-check the listed `volatile_claims` before relying on them. If `contradiction` is set or today is on or after `next_due`, tell the user in one line, do the task with the current content, then run the refresh (`evergreen-refresh`) in the same session. If `tests.failing` is non-empty, say so in one line and run `evergreen-tune` after the task. Never block the task on a refresh unless the task depends on the stale claim.

## Step 1: confirm the target and ask before mutating

Read `Packages/manifest.json` (dependencies and any `scopedRegistries`) and `ProjectSettings/ProjectVersion.txt`. A package change edits a tracked file and triggers a domain reload in an open Editor, so state the exact change and get a yes unless the user already asked for precisely this.

## Step 2: pick the route

| Editor state | Route |
|---|---|
| Open with `com.unity.pipeline` reachable (check with `unity pipeline list`; if `unity` is not on PATH yet, call `"$env:LOCALAPPDATA\Unity\bin\unity.exe"`) | `unity command package_add --name com.unity.x[@ver]` then poll `unity command package_status`; `package_remove`, `package_resolve`, `package_list` likewise (unity-agent-cli) |
| Closed | the Client API script (Step 3), run with `Unity.exe -batchmode -projectPath <p> -executeMethod ProjectBootstrap.PackageInstaller.Install -logFile -` **without `-quit`** (the request completes on later Editor ticks and the script exits itself); `unity run` cannot be used because it injects `-quit` |
| Closed, simple pin or OpenUPM/git package, user wants a diff they can review | edit `Packages/manifest.json` by hand: add `"com.x.y": "1.2.3"`, a git URL `"https://github.com/org/repo.git?path=/Pkg#v1.2.3"`, or a scoped registry block for OpenUPM (`https://package.openupm.com` with `scopes`); the next Editor open resolves it. Keep `packages-lock.json` (Unity regenerates it; delete it only to force a full re-resolve) |

Unity's own guidance prefers the Client API over hand edits because it resolves compatible versions; hand edits are fine for pinned versions the user chose.

## Step 3: the Client API script

`references/PackageInstaller.cs` (from Unity's `unity-package-management` skill, MIT) goes under an `Editor/` folder, lists packages to add or remove, calls `Client.AddAndRemove` once, polls on `EditorApplication.update`, and ends with `EditorApplication.Exit(0|1|2)`. `PackageSearch.cs` in the same reference lists registry packages and versions the same way. Edit the arrays, run headless as in Step 2, watch the `[PackageInstaller]` lines in the streamed log, then verify.

## Step 4: verify

1. `Packages/manifest.json` contains the id and version.
2. `<project>/Logs/upm.log` has no `error` for that package; a resolve error names the missing dependency or the wrong version.
3. The Editor is not in Safe Mode afterwards (`unity pipeline list` shows `safeMode: false`, or the batchmode log lacks `Scripts have compiler errors`).
4. If the package brings code, run the compile check (unity-agent-headless).

## Step 5: AI-related packages and version traps (state when relevant)

- `com.unity.pipeline` (experimental 0.4.x, Unity 6.0+): the agent bridge; install with `unity pipeline install`; pin the version.
- `com.unity.ai.assistant`, `com.unity.ai.generators`, `com.unity.ai.inference`: Unity AI. Assistant needs a Unity Cloud project; its in-Editor MCP is deprecated in favour of the CLI. On Unity 6000.5.x, Assistant 2.13-pre livelocked the AssetDatabase at startup (UUM-132096, June 2026): avoid until a fixed version is confirmed at refresh.
- `com.unity.test-framework` 1.7 or 2.0 (2.0 changes `-testResults` relative-path resolution and prints a settings summary in batchmode).
- `com.unity.testtools.codecoverage` enables `unity test --coverage`.
- OpenUPM packages need the scoped registry block; `openupm-cli` (`openupm add com.x.y`) writes it for you.

## Output

The manifest diff (or the command that ran), then the verification lines: manifest entry, upm.log clean, Safe Mode false or compile check green.

## While working: capture learnings

If the user corrects you, the same error happens twice, a workaround is found, or an environment fact is discovered, write it to `LEARNINGS.md` now (format in MAINTENANCE.md; check existing entries first: add, update, retire, or nothing). If a learning proves a claim above wrong, fix it here, log it in `CHANGELOG.md`, and set `contradiction` in `evergreen.json`.

## Maintenance

This skill is evergreen (topic: Unity Package Manager from the command line and scripts; tier `moderate`, currently every 30d, next due 2026-10-06). Files: `evergreen.json` (state), [RESEARCH.md](RESEARCH.md) (findings and search plan), [CHANGELOG.md](CHANGELOG.md) (every change, with reasons), [LEARNINGS.md](LEARNINGS.md) (lessons), [TESTS.md](TESTS.md) and `evals/evals.json` (the cases that prove it and the runs). Protocol: MAINTENANCE.md (pointer to the installed evergreen plugin). Refresh with `evergreen-refresh`; test with `evergreen-test`; fix a failure with `evergreen-tune`; audit with `evergreen-audit`. Sibling skills in this suite: unity-agent-cli, unity-agent-headless, unity-agent-mcp, unity-agent-workflow, unity-agent-packages.
