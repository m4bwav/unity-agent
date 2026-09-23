---
name: unity-agent-cli
description: "Drive Unity from the terminal with the official Unity CLI (the unity binary, beta since July 2026) and its com.unity.pipeline package: list or install editors and modules, open or close a project, see which Editors are running, run EditMode/PlayMode tests with a results report, build players, execute registered Editor commands or C# eval against a running Editor, and start or configure Unity's built-in MCP server. Use whenever the user asks to control, script, automate, or talk to Unity, Unity Hub, or the Unity Editor from the command line, mentions the Unity CLI, unity status, unity test, unity build, unity command, the Pipeline package, or asks 'can Claude drive the editor', 'run the Unity tests', 'which editors are installed', 'is the editor open', 'install Unity 6.x', or 'refresh unity-agent-cli' / 'is unity-agent-cli stale'. Batchmode work with no CLI is the sibling unity-agent-headless skill; choosing an MCP server is unity-agent-mcp."
---

# Unity CLI (official `unity` binary + com.unity.pipeline)

Outcome: the requested Unity action is performed through the official CLI and the result is
proven by the CLI's JSON (`success`), an exit code, or a file it wrote, never by prose.

## Step 0: freshness (every use, one read)

Read `evergreen.json` next to this file. If `verify_at_use` is true, re-check the listed `volatile_claims` before relying on them. If `contradiction` is set or today is on or after `next_due`, tell the user in one line, do the task with the current content, then run the refresh (`evergreen-refresh`) in the same session. If `tests.failing` is non-empty, say so in one line and run `evergreen-tune` after the task. Never block the task on a refresh unless the task depends on the stale claim.

## Step 1: probe before acting

Run the probe once and read its JSON; it answers every "is X installed / open / reachable" question in one call:

```powershell
powershell -NoProfile -File "<this folder>\scripts\unity_probe.ps1" -Project "<abs project path>"
```

It reports: CLI path and version (or `null`), installed editors, running Editor processes with their project paths, whether each open project has the Pipeline package and a reachable server, `Temp/UnityLockfile` presence and whether it is stale, and which .NET SDKs are reachable (system, then the one bundled inside each Unity install). Do not guess any of these.

CLI missing: install it (user-level, `%LOCALAPPDATA%\Unity\bin` or `UNITY_CLI_HOME`, checksum-verified, adds itself to the user PATH; no admin; the latest beta until a stable release exists):

```powershell
irm https://unity.com/install.ps1 | iex
```

`winget install Unity.CLI` works too, and Unity Hub 3.21+ installs the CLI on first launch. A shell opened before the install does not see the new PATH: call it by full path `"$env:LOCALAPPDATA\Unity\bin\unity.exe"` until the user restarts the terminal. `unity self-update` updates; `unity self-uninstall` removes it.

## Step 2: pick the route

| Situation | Route |
|---|---|
| Editor for this project is open **and** `pipeline list` shows `hasPipelinePackage: true` and `isReachable: true` | Live commands: `unity command ...`, `unity list`, `unity mcp` |
| Editor open but no Pipeline package | Ask before `unity pipeline install` (edits `Packages/manifest.json`). The open Editor resolves it only when the user stops Play mode and clicks into its window (programmatic focus does nothing); wait for `Library/Pipeline/.unity-pipeline-port` or `unity status` = ready. Until then only read-only work; never hand-edit scene or prefab YAML while that Editor is open |
| Editor closed | `unity test`, `unity build`, `unity run` spawn a batchmode Editor themselves. Never run them while that project's Editor is open (project lock) |
| Editor open (the probe's `running` lists it) but `unity status` fails or reports no instances | Safe Mode from C# compile errors (`unity pipeline list` shows `safeMode`; fix the compile error first, unity-agent-headless has the offline compile check), or the agent's sandbox hiding a running Editor: say so and ask; never swap in a batchmode Editor or hand edits |

Always add `--format json --no-banner` when the output will be parsed, read stdout only, and branch on `success`, not on `data` (`--result-only` prints the Editor's result without that envelope, so do not combine it with success checks). With more than one Editor open pass `--project-path <abs path>` (the CLI errors with `AMBIGUOUS_EDITOR` otherwise).

## Step 3: the commands that matter

Editors and Hub:
- `unity editors --format json` (installed plus releases; `--installed` only local), `unity editors path <version>` (install dir), `unity install <version> -m <modules...>`, `unity install-modules`, `unity uninstall <version>`, `unity releases`, `unity env`, `unity doctor` (auth state, editors, PATH, tools), `unity logs` (the CLI/Hub log, not the Editor log).
- `unity open <project>` opens with the pinned editor version; `unity close <project>` exits without saving. `unity projects` manages the Hub registry.
- Hub's own `"Unity Hub.exe" -- --headless ...` CLI is deprecated since Hub 3.18; use it only when the `unity` binary cannot be installed (procedure in unity-agent-headless).

Live Editor (needs the Pipeline package):
- `unity status` (reachable Editors), `unity pipeline list`, `unity list` or bare `unity command` (about 150 registered commands, 149 on Pipeline 0.6.0-exp.1; `--query <term>`, `--tag <tag>`; `unity commands --format json` prints the CLI's own command tree), `unity command <name> [--arg value ...]`, `unity command eval "C# statement;"` (Roslyn, Editor main thread; keep statements short), `unity command menu --path "Tools/..."`.
- Verification loop after a code change: files edited from a shell are not imported until the AssetDatabase refreshes (a CLI-driven Editor never regains focus), so first `unity command eval "UnityEditor.AssetDatabase.Refresh(); return 1;"` (L-007). Then `unity recompile --format json` (CLI 1.0.0-beta.11+: exit 0 compiled, 6 compile errors with file and line, 7 no Editor answered and safe to retry). On an older CLI: `unity command recompile`, poll `recompile_status`, then `unity command console --level error` (`get_console_logs` was removed in Pipeline 0.7.0-exp.1). Screens: `unity command capture_game_view --source screen --save_path Shots~/x.png` in Play Mode is the only capture that includes UI Toolkit runtime UI; `screenshot --view game` and `--source camera` render the camera only (L-004). Set `Application.runInBackground = true` by `eval` after `editor_play` or the capture is a stale frame (L-005). Play mode: `editor_play` and `editor_stop`; after `open_scene` or `editor_stop` wait about 3 s, send `editor_play`, poll `editor_status` for up to 20 s and re-send it (up to 4 tries) if play mode never starts, because a request that lands while the Editor is busy is dropped silently (L-006).
- Mutating commands take `--dry_run true` (preview) and refuse without `--confirm true`; scene and GameObject edits are one Undo step, while asset, package and settings writes are not undoable. Most authoring commands are blocked in Play mode.
- Long operations return at once; poll the matching status command (`build_status`, `test_status`, `package_status`, `recompile_status`). `--detach` submits a job (`unity job`). The Editor may stop ticking when unfocused: `unity command set_autotick --enable true` first (resets on domain reload).
- Raw HTTP when the CLI cannot be used: descriptor `<project>/Library/Pipeline/.unity-pipeline-port` (JSON with `port`, `pid`, `projectPath`, `evalToken`); `POST http://127.0.0.1:<port>/api/exec` with header `Authorization: Bearer <evalToken>` and body `{"command":"<name>","parameters":{...}}` (the key is `parameters`, not `params`). Re-read the descriptor after any domain reload; never print, log or commit the token; use `127.0.0.1`, not `localhost`.

Tests and builds (spawn batchmode; that project's Editor must be closed):
- `unity test <project> --mode EditMode|PlayMode [--filter <name>] [--output results.xml] [--report-format nunit,junit] [--retries N] [--timeout S]`. Exit 0 = all passed, **8 = tests failed** (never retry), 6 = the run did not finish (compile error, license, crash, timeout), 7 = a Unity service or Editor was unreachable, 2 = usage; any command: 1 general, 3 auth, 4 configuration required, 130/143 interrupted. Retry a test run only on 6 or 7. Parse the NUnit XML `total` and `failed` attributes; do not stop at the exit code.
- `unity build <project> --target StandaloneWindows64 --output-path <exe>`, or `--profile "<name>"` (Unity 6 build profiles), or `--execute-method <Class.Method>`; log goes to `<project>/Logs/build-<target>-<timestamp>.log`; `--allow-dirty-build` skips the uncommitted-changes guard.
- `unity run <project> -- -executeMethod <Class.Method> -logFile <path>` for any other batchmode entry point. `unity run` injects `-batchmode -quit -projectPath` itself and refuses them as arguments (exit 6). Anything asynchronous inside the Editor (UPM `Client.Add`, async imports) needs the Editor alive after the method returns, so launch `Unity.exe -batchmode` directly without `-quit` for those (unity-agent-packages).

MCP mode:
- `unity mcp` starts a stdio MCP server exposing the Pipeline commands; `unity mcp configure --list` shows every supported client (Claude Desktop, VS Code and Copilot, Copilot CLI, Cursor, Codex, Windsurf, Cline, Zed, Continue, Kiro, ...) and `unity mcp configure <client> [--project-path <p>]` writes the entry. Claude Code has no file for the CLI to write; register it with `claude mcp add unity -- unity mcp --project-path "<abs project>"`. When the Editor's main thread is blocked, `capture_game_view` and `capture_scene_view` over MCP fall back to a screenshot of the whole desktop (they say so in a note): check the image before quoting it as evidence. Decide CLI vs MCP with unity-agent-mcp.

Skills Unity ships: `unity skill show` prints Unity's task-oriented CLI guide without installing anything; use it for any flag not listed here. `unity skill install <client> [--local]` copies Unity's own `unity-cli` skill (and, with `--local` and the package present, the package's `unity-pipeline` skill) into the client's skills folder; in Claude Code the official plugin installs with `/plugin marketplace add Unity-Technologies/unity-agent-plugin` then `/plugin install unity@unity-agent-plugin`. Both overlap this skill: ask before installing.

## Step 4: prove it, then report

The action is done only when its evidence exists: the JSON `success: true`, the exit code, the results XML, the build output path, or the descriptor showing the change. Quote the evidence in one line. On failure quote `errors[0].code` and its message.

## Output

One to three lines: what ran (the exact command), the evidence, and the next decision if any (for example "Pipeline package is not in this project; say the word and I run `unity pipeline install`").

## While working: capture learnings

If the user corrects you, the same error happens twice, a workaround is found, or an environment fact is discovered, write it to `LEARNINGS.md` now (format in MAINTENANCE.md; check existing entries first: add, update, retire, or nothing). If a learning proves a claim above wrong, fix it here, log it in `CHANGELOG.md`, and set `contradiction` in `evergreen.json`.

## Maintenance

This skill is evergreen (topic: the official Unity CLI and com.unity.pipeline package; tier `fast`; the schedule is in `evergreen.json`). Files: `evergreen.json` (state), [RESEARCH.md](RESEARCH.md) (findings and search plan), [CHANGELOG.md](CHANGELOG.md) (every change, with reasons), [LEARNINGS.md](LEARNINGS.md) (lessons), [TESTS.md](TESTS.md) and `evals/evals.json` (the cases that prove it and the runs). Protocol: MAINTENANCE.md (pointer to the installed evergreen plugin). Refresh with `evergreen-refresh`; test with `evergreen-test`; fix a failure with `evergreen-tune`; audit with `evergreen-audit`. Sibling skills in this suite: unity-agent-cli, unity-agent-headless, unity-agent-mcp, unity-agent-workflow, unity-agent-packages.
