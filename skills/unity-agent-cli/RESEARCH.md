# Research: unity-agent-cli

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: the official Unity CLI (unity binary, beta) and com.unity.pipeline package: commands, exit codes, MCP mode, editor install, and how agents drive a running Unity Editor. Tier `fast`. Last refresh 2026-09-22; next due per `evergreen.json`.

## Current understanding

- Unity shipped a standalone `unity` CLI on 2026-07-20 (blog "Meet the Unity CLI"); the first install (2026-09-06) was 1.0.0-beta.8 and the current release on 2026-09-22 is 1.0.0-beta.11, installed to `%LOCALAPPDATA%\Unity\bin\unity.exe` with a SHA-256-verified download and a user-PATH edit. Since beta.11 `irm https://unity.com/install.ps1 | iex` (and `install.sh`) installs the latest beta when no channel is set, until a stable release exists; `winget install Unity.CLI` and a Homebrew cask have existed since beta.4, and Unity Hub 3.21+ installs the CLI on first launch. Verified by a test install on 2026-09-06.
- The command surface (from `unity --help` on beta.8): editors, install, install-modules, uninstall, releases, open, close, projects, templates, auth, license, cloud, vcs, doctor, env, logs, hub, pipeline (install/upgrade/list/list-versions), status, list, command, job, shell, test, build, run, mcp (start server; `configure <client>`), skill (install Unity's own skill), self-update, self-uninstall. Global `--format json|tsv|ndjson|github`, `--no-banner`, `--non-interactive`. Since then: beta.9 renamed `install --list-components` to `--list-modules` and added `unity test --affected --since <ref>`; beta.10 added `unity commands --format json` (the CLI's own command manifest) and `unity command <name> --result-only` (the Editor's result without the envelope); beta.11 added `unity recompile` (exit 0 compiled, 6 compile errors with file and line, 7 no Editor answered), `unity docs <topic>`, `unity assets export|import` and `unity mcp configure --server issue-tracker`.
- Live Editor control needs the experimental `com.unity.pipeline` package (0.4.0-exp.1 in the first docs read, 0.6.0-exp.1 installed 2026-09-06, 0.7.0-exp.1 released 2026-09-10, 0.8.0-exp.1 released 2026-09-22; Unity 6.0+). It runs an HTTP server on 127.0.0.1 (Editor ports 7800-7849), writes `<project>/Library/Pipeline/.unity-pipeline-port` (pid, port, projectPath, mode editor|batchmode, lastHeartbeat, evalToken), and exposes `/api/status`, `/api/editor_status`, `/api/commands`, `POST /api/exec` (`{"command","parameters"}`), `/api/test-status`. The token persists in SessionState across domain reloads within a session (package docs); an early third-party report said it rotated on Play mode. Mutating commands use `dry_run`/`confirm` gates; scene edits are one Undo step. 0.7.0-exp.1 removed `get_console_logs` (use `console`: `level` log|warn|error as a minimum severity, `tail` default 100, `since` cursor), added `console_status` and `compilationFailed` in `recompile_status`, fixed `recompile` answering `up_to_date` over standing compile errors, and leaves its runtime assemblies out of non-Development Players unless `ENABLE_RUNTIME_PIPELINE` is defined. 0.8.0-exp.1: `capture_game_view` defaults to `source=screen` and is documented to work in Edit Mode; the nine `*_status` commands return a JSON object instead of a string; servers bind 127.0.0.1 and answer only requests addressed to it; Editor server settings live in Project Settings > Pipeline > Editor; `codereload_status` and `cleanup_codereload` on the Editor server; `simulate_key` and `simulate_pointer` report a missing Input System. The 0.8 manual documents no server-side `wait` command. CLI beta.10 added `unity context`, `unity build --list-targets`/`--list-profiles`/`--create-profile` and `unity build run`; no release after beta.11 as of 2026-09-26.
- `unity test` spawns batchmode and writes NUnit (or JUnit) XML; exit 0 pass, 8 tests failed (never retry), 6 the run did not finish (compile error, license, crash, timeout), 7 a Unity service or Editor unreachable (the CLI already retried; safe to retry), 2 usage; any command also uses 1 general, 3 auth, 4 configuration required, 130/143 interrupted (CLI reference, read 2026-09-22). `unity build` spawns batchmode with targets or Unity 6 build profiles. `unity run` injects `-batchmode -quit -projectPath` and refuses those flags (exit 6), so async Editor work needs direct `Unity.exe -batchmode` without `-quit`.
- `unity mcp` is a stdio MCP server over the Pipeline commands; `unity mcp configure --list` (beta.8) lists 17 clients (Claude Desktop, Cursor, VS Code, Copilot CLI, Codex, Windsurf, Cline, Zed, Continue, Kiro, Kimi, Antigravity, ...); beta.8 showed Claude Code as "delegation/manual", but Unity's skill reference for beta.10 lists 16 client ids including `claude-code`, so `unity mcp configure claude-code` now writes the entry (`claude mcp add --scope local` stays the manual route). Unity's Assistant 2.18 docs mark the in-Editor MCP server deprecated in favour of the CLI. Unite Seoul 2026 stated CLI and MCP are free.
- Unity ships an official skills repo (Unity-Technologies/skills, MIT, ~950 stars by 2026-09-22, `npx skills add Unity-Technologies/skills`) with a `unity-cli` skill; `unity skill install <client>` installs it; a `--local` install also mirrors the package's `unity-pipeline` skill. This skill stays self-contained but points there and uses a non-colliding name. On 2026-09-09 Unity also published an official Claude Code plugin, Unity-Technologies/unity-agent-plugin (0.1.6-beta, ~330 stars, CLI-first, no MCP server), installed with `/plugin install unity@unity-agent-plugin`; `unity skill show` prints the task-oriented CLI guide without installing anything. Unity's skill warns that an agent's sandbox can hide a genuinely running Editor from `unity status`.
- Hub's headless CLI is deprecated from Hub 3.18 (docs.unity.com); it still works (verified 2026-09-06) once `ELECTRON_RUN_AS_NODE` is cleared.
- Verified on the development machine: `unity editors`, `unity pipeline list` (sees the open Editor of a Unity 6 game project, `hasPipelinePackage: false`), `unity status` (STATUS_NO_INSTANCES until the package is installed), `unity doctor` (logged in to a Unity account via OAuth). At that point no project had the Pipeline package yet, so `unity command` and `unity mcp` are unverified locally.

## Open questions

- Does the Pipeline token survive Play-mode domain reloads in 0.4.0-exp.1 (docs say yes; Vindler's July report said no; re-test once the package is installed).
- Exact `unity mcp` tool list and whether it supports `mode: batchmode` descriptors.
- When does the CLI leave beta? (winget packaging resolved: `Unity.CLI` since beta.4; the install line changed in beta.11.)
- Parameters of the server-side `wait` command mentioned in the Pipeline 0.7 changelog, which might replace L-006's retry loop (not in the 0.8 manual, 2026-09-26).
- On Pipeline 0.8: does `capture_game_view` (default screen source) include UI Toolkit runtime UI in Edit Mode, and does L-004 still hold?
- The eval timeout: the skill no longer states the unverified 5 s default; check `unity command eval --help` on the next live run.
- The development machine still runs CLI beta.8; `unity recompile` needs beta.11 (`unity self-update` is the user's call).
- (resolved 2026-09-06) `com.unity.pipeline` 0.6.0-exp.1 runs on 6000.5.0f1; 149 commands registered.

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `unity.com/blog unity cli <month year>`; Unity Discussions "Unity CLI 1.0.0-beta.N is rolling out" threads, the fastest source (fetch `discussions.unity.com/raw/<topic id>` with a browser user agent; the JSON API refuses crawlers); docs.unity.com/en-us/unity-cli/release-notes (renders now, lags the threads by days) and /unity-cli-reference (exit codes); `unity changelog` offline; the Unity-Technologies/skills raw SKILL.md mirror
- `docs.unity3d.com/Packages/com.unity.pipeline@<minor>/manual` and `/changelog/CHANGELOG.html` (an explicit minor such as `@0.8`; `@latest` 404s; try the next minor, `@0.9`, first); `unity pipeline list-versions`
- `"com.unity.pipeline" OR "unity pipeline install" site:discussions.unity.com <year>`

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `path:SKILL.md "unity cli" OR "com.unity.pipeline"` on GitHub code search, sorted by recently updated; `npx skills find unity` and skills.sh for install counts; github.com/Unity-Technologies/skills commits
- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; fallback `unity mcp server site:glama.ai OR site:pulsemcp.com`
- `"unity cli" skill OR plugin OR "mcp server" <year> site:github.com`

Practice (how others use AI agents on this goal, and everything in between):

- `"unity cli" OR "unity pipeline" "claude code" OR codex OR cursor workflow <year>`; vindler.solutions; discussions.unity.com "CLI/MCP/AI IDE" threads
- hn.algolia.com `"unity cli"` sorted by date; r/Unity3D `unity cli agent` with a date filter

Testing (how the job is verified and what checkers exist):

- `unity test exit code 8 nunit xml <year>`; UTF 2.0 changelog; `"unity test" flaky retries shard`
- `GameDevBench arxiv unity agent benchmark <year>`

Best sources (primary first): unity.com/blog, docs.unity3d.com package manuals (fetch fine), the CLI's own `--help` and `changelog`, github.com/Unity-Technologies/skills, github.com/CoplayDev/unity-mcp issues for pitfalls. Noisy: docs.unity.com (returns titles only), mcpservers.org listings, YouTube explainers.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20260926-2 · 2026-09-26 · Tooling, practice, testing: install velocity, community wrappers, a parsing case
- summary: Unity-Technologies/skills commits of 2026-09-21 to 25 are README pointers, a frontmatter CI check, URP-default project creation and a restored skill; none changes `unity-cli` guidance. skills.sh: `unity-cli` 6.1K installs (about 75 a day; next is unity-package-management at 5.1K); unity-agent-plugin 0.1.6-beta, 357 stars, no MCP server. Practice: itsdevlogger/unity-cli-skill (9 stars, Windows only, no tests) wraps the CLI; Nice-Wolf-Studio/unity-claude-skills issue #4 proposes `unity test` over raw `-runTests` for the exit-code contract (the skill already says so). Testing: nothing new since GameDevBench; a candidate case is parsing `recompile_status` as an object on Pipeline 0.8.
- track: tooling, practice, testing
- sources: https://github.com/Unity-Technologies/skills/commits/main, https://skills.sh/Unity-Technologies/skills, https://github.com/Unity-Technologies/unity-agent-plugin, https://github.com/itsdevlogger/unity-cli-skill, https://github.com/Nice-Wolf-Studio/unity-claude-skills/issues/4, https://arxiv.org/abs/2602.11103v1
- magnitude: 0.2
- applied: note (the parsing case waits for a live 0.8 run)

### R-20260926-1 · 2026-09-26 · Subject: Pipeline 0.8.0-exp.1 changes capture, status payloads and binding; CLI beta.10 build commands
- summary: The 0.8.0-exp.1 changelog (2026-09-22, missed by the last refresh): `capture_game_view` defaults to `source=screen` and works in Edit Mode; the nine `*_status` commands return real JSON instead of a JSON string; servers bind 127.0.0.1 and answer only requests addressed to 127.0.0.1; the Editor server is configured in Project Settings > Pipeline > Editor; `codereload_status` and `cleanup_codereload` on the Editor server; missing Input System reported by `simulate_key`/`simulate_pointer`; `/api/commands?detail=tags` one row per tag. The 0.8 manual documents no `wait` command. CLI beta.10 (2026-09-14) added `unity context`, `unity build --list-targets`, `--list-profiles`, `--create-profile` and `unity build run`; nothing after beta.11.
- track: subject
- sources: https://docs.unity3d.com/Packages/com.unity.pipeline@0.8/changelog/CHANGELOG.html, https://docs.unity3d.com/Packages/com.unity.pipeline@0.8/manual/index.html, https://docs.unity3d.com/Packages/com.unity.pipeline@0.8/manual/commands/runtime.html, https://discussions.unity.com/t/unity-cli-1-0-0-beta-10-is-rolling-out/1736729, https://docs.unity.com/en-us/unity-cli/release-notes
- magnitude: 0.4
- applied: C-20260926-1

### R-20260922-5 · 2026-09-22 · Testing: the full exit-code table, `--result-only`, and a command-manifest check
- summary: The CLI reference now documents every exit code: 0 success, 1 general, 2 usage, 3 auth, 4 configuration required, 6 primary operation failed (for `unity test`, the run did not finish), 7 a Unity service could not be reached (already retried; safe to retry), 8 `unity test` only, tests failed (never retry), 130/143 interrupted; CI should retry a test run only on 6 or 7. beta.10's `--result-only` drops the `success` envelope, and `unity commands --format json` gives the CLI's own command manifest, which lets a check compare the commands this skill names against the installed CLI.
- track: testing
- sources: https://docs.unity.com/en-us/unity-cli/unity-cli-reference, https://docs.unity.com/en-us/unity-cli/release-notes
- magnitude: 0.3
- applied: C-20260922-2 (SKILL.md Step 2 JSON note, Step 3 tests line; evals action-3)

### R-20260922-4 · 2026-09-22 · Tooling: Unity's official Claude Code plugin and `unity skill show`
- summary: Unity published Unity-Technologies/unity-agent-plugin on 2026-09-09 (listed in Claude's plugin directory; 0.1.6-beta, ~330 stars, pushed 2026-09-22): `/plugin marketplace add Unity-Technologies/unity-agent-plugin`, then `/plugin install unity@unity-agent-plugin`, installs Unity's skills including `unity-cli`, CLI-first with no MCP server. Unity-Technologies/skills grew to ~950 stars; skills.sh counts ~5.8K installs of `unity-cli`, the most of any Unity skill. `unity skill show` (beta.9+) prints the version-matched task guide without installing. Response: point (this skill keeps the route and evidence rules and names Unity's plugin as the full command reference).
- track: tooling
- sources: https://unity.com/blog/unity-plugin-for-claude-code, https://github.com/Unity-Technologies/unity-agent-plugin, https://skills.sh/Unity-Technologies/skills
- magnitude: 0.5
- applied: C-20260922-2 (SKILL.md Step 3 skills line)

### R-20260922-3 · 2026-09-22 · Practice: an agent's sandbox can hide a running Editor
- summary: Unity's `unity-cli` skill warns that a restrictive sandbox "can hide a genuinely running Editor from `unity status`": an agent must not read "no instances" as proof the Editor is closed, and must not switch to a batchmode Editor or file edits without telling the user.
- track: practice
- sources: https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-cli/SKILL.md
- magnitude: 0.3
- applied: C-20260922-2 (SKILL.md Step 2 route table)

### R-20260922-2 · 2026-09-22 · Subject: CLI beta.9 to beta.11: new install line, `unity recompile`, packaging that already existed
- summary: beta.11 (2026-09-22): `irm https://unity.com/install.ps1 | iex` installs the latest beta when no channel is set, until a stable release; `unity recompile` checks compilation in the running Editor and exits 0, 6 (errors with file and line) or 7 (no Editor answered); usage errors honour `--format json` (`INVALID_COMMAND_ARGS`); plus `unity docs`, `unity assets export|import`, `unity editors prune`, `unity mcp configure --server issue-tracker`. beta.10: `unity commands --format json`, `--result-only`, `unity status` reports `starting`, and MCP captures fall back to a whole-desktop screenshot when the Editor's main thread is blocked. beta.9: `--list-components` renamed `--list-modules`, `unity test --affected --since <ref>`. Missed at the last check: winget `Unity.CLI` and a Homebrew cask exist since beta.4, and Hub 3.21 installs the CLI on first launch, so the "packaging coming soon" line was already wrong.
- track: subject
- sources: https://discussions.unity.com/t/unity-cli-1-0-0-beta-11-is-rolling-out/1737353, https://unity.com/install.ps1, https://docs.unity.com/en-us/unity-cli/release-notes, https://unity.com/unity-hub/release-notes, `winget show --id Unity.CLI` (2026-09-22)
- magnitude: 0.4
- applied: C-20260922-2 (SKILL.md Step 1 install, Step 3 verification loop and MCP mode)

### R-20260922-1 · 2026-09-22 · Subject: Pipeline 0.7.0-exp.1 removed `get_console_logs`, the command the verification loop used
- summary: The 0.7.0-exp.1 changelog (2026-09-10): "Removed get_console_logs, which duplicated console over a second buffer of its own ... Use console". `console` takes `level` (minimum severity log|warn|error), `tail` (default 100) and a `since` cursor. Also: `console_status`, `compilationFailed` in `recompile_status`, a fix for `recompile` reporting `up_to_date` while compile errors stood, and runtime assemblies left out of non-Development Players unless `ENABLE_RUNTIME_PIPELINE` is defined. The skill's verification loop (`get_console_logs --severity error`) would fail on any project that takes the update.
- track: subject
- sources: https://docs.unity3d.com/Packages/com.unity.pipeline@0.7/changelog/CHANGELOG.html, https://docs.unity3d.com/Packages/com.unity.pipeline@0.7/manual/commands/runtime.html
- magnitude: 0.6
- applied: C-20260922-2 (SKILL.md Step 3 verification loop)

### R-20260906-5 · 2026-09-06 · Pipeline 0.6.0-exp.1 verified live on a Unity 6 game project: 149 commands, port 7800
- Summary: `unity pipeline install` wrote `com.unity.pipeline` 0.6.0-exp.1 (newer than the 0.4 docs) into the manifest; the open Editor resolved it only after the user clicked into its window (a Play-mode session and programmatic SetForegroundWindow both left it unresolved). After the reload: `unity status` shows the instance `ready` on port 7800, `editor_status` returns compiling/playMode/heartbeat, `unity command` lists 149 registered commands (animation, timeline, prefabs, scenes, tests, build, capture, packages, eval). `unity skill install claude-code --local` then also installed the package's `unity-pipeline` skill into the project. The `unity mcp` server exposes the same 149 commands as tools: about 96 KB of JSON schema, roughly 24k tokens if a client loads every schema (Claude Code defers MCP schemas, so the standing cost is the name list).
- Track: testing
- Sources: local runs 2026-09-06 (`unity status`, `unity command editor_status`, `unity command --format json`, MCP stdio probe)
- Magnitude: 0.3 (Pipeline version and command count updated; resolution needs real focus)
- Applied: C-20260906-3

### R-20260906-4 · 2026-09-06 · Local verification of the CLI on the development machine
- Summary: Installed 1.0.0-beta.8 from the reviewed install script; `unity editors`, `pipeline list`, `status`, `doctor`, `mcp configure --list` all ran. The open Editor of a Unity 6 game project (6000.5.0f1) is listed with `hasPipelinePackage: false`; `status` returns `STATUS_NO_INSTANCES`. The CLI carries a .NET 10 runtime (`nodeVersion .NET 10.0.11` in doctor). `unity skill` and `unity job` exist and are not on the blog.
- Track: testing
- Sources: local runs 2026-09-06 (`unity --help`, `unity doctor`)
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-3 · 2026-09-06 · Pipeline package connectivity and safety (docs 0.4.0-exp.1)
- Summary: Descriptor path and JSON shape, bearer token in `SessionState` (survives domain reloads within a session, regenerates on Editor restart), endpoints, port ranges, `127.0.0.1` not `localhost`, dry_run/confirm convention, `AuthoringUndoScope`, path confinement to `Assets`. A third-party skill (menstood/unity-pipeline-commands-skill) adds: body key must be `parameters`, re-read the descriptor after Play mode, `set_autotick` when unfocused, `get_console_logs` can return 0 while Editor.log has lines.
- Track: subject
- Sources: https://docs.unity3d.com/Packages/com.unity.pipeline@0.4/manual/connectivity.html, https://docs.unity3d.com/Packages/com.unity.pipeline@0.4/manual/safety-and-mutations.html, https://github.com/menstood/unity-pipeline-commands-skill
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-2 · 2026-09-06 · Official Unity skills repo and `unity skill install`
- Summary: Unity-Technologies/skills (MIT, ~730 stars, 13-14 skills) documents `unity status` before editing files, Safe Mode blocking, `--format json` parsing rules, `AMBIGUOUS_EDITOR`, and exit codes (0/2/6/8) in `references/build-run-test.md`. The CLI's `unity skill install <client>` copies it. Response: point; keep this skill self-contained and non-colliding (different name).
- Track: tooling
- Sources: https://github.com/Unity-Technologies/skills, https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-cli/SKILL.md, https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-cli/references/build-run-test.md
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Unity CLI launch and MCP deprecation in the Assistant
- Summary: Blog 2026-07-20: single self-contained binary, beta channel install lines, `com.unity.pipeline` for a running Editor or dev Player, eval token-gated, runtime API localhost-only and off by default. Assistant 2.18 docs: "Unity MCP server is deprecated. Use the Unity CLI instead." Unite Seoul 2026-07-21: CLI and MCP free; Unity 6.6 defaults Fast Enter Play Mode; Unity 7 preview Dec 2026. Hub CLI deprecated from Hub 3.18.
- Track: subject
- Sources: https://unity.com/blog/meet-the-unity-cli, https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.18/manual/integration/unity-mcp-get-started.html, https://unity.com/blog/unite-seoul-keynote-2026-recap, https://docs.unity.com/en-us/hub/use-hub-cli
- Magnitude: n/a (initial)
- Applied: C-20260906-1
