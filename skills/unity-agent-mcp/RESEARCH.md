# Research: unity-agent-mcp

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: MCP servers that bridge AI agents to the Unity Editor: Unity's official unity mcp mode, CoplayDev, IvanMurzak, CoderGamester, docs servers; client configuration and domain-reload pitfalls. Tier `fast`. Last refresh 2026-10-23; next due per `evergreen.json`.

## Current understanding

- Official route (since July 2026): the Unity CLI's `unity mcp` stdio server over `com.unity.pipeline` (0.9.0-exp.1 on 2026-10-20 grouped the commands and dropped the old flat names; 0.9.1-exp.1 is `latest` on 2026-10-23; pair it with CLI beta.14, since beta.13 sends old names; Unity 6.0+; the Unity 7 MSBuild build block is fixed in a later Unity 7 alpha, not in Pipeline, per staff on 2026-10-15). Free, no Unity AI subscription. `unity mcp configure <client>` writes the config for 16 client ids (beta.10), `claude-code` included (`--dry-run` previews); CLI beta.14 (2026-10-21) adds `unity mcp --tools` / `--exclude-tools` filters that match grouped and old names, and `--instance`/`--pid`/`--port` pinning; `claude mcp add --scope local` stays the manual route; from CLI beta.12 (2026-09-30) `configure claude-code` skips with a warning when an enabled plugin already runs `unity mcp` for the project. Unity's official Claude Code plugin (2026-09-09; 0.1.8-beta on 2026-10-01, also installable with `unity setup claude`) is CLI-first and still registers no MCP server. The older in-Editor "Unity MCP" (com.unity.ai.assistant 2.x, relay in `~/.unity/relay/`, needs Unity Cloud plus an AI beta seat) is marked deprecated in Assistant 2.18 docs.
- Community ranking by adoption (stars, last commit): CoplayDev/unity-mcp (MIT, ~15.4k stars, v10.3.0 on 2026-10-04 still the latest release on 2026-10-23, `main` at 10.3.1-beta.11; Unity 2021.3 to 6.x; 47 tools in groups, only `core` on by default; Python/uv server) > IvanMurzak/Unity-MCP (Apache-2.0, ~4.5k, 1.5.0 on 2026-10-24 UTC; 1.0.0 replaced the data and profiler tools with RQL, 1.1.0 split the add-ons into separate packages, 1.4.0 fixed a Unity 7 CoreCLR startup hang; about 60 named tools plus RQL sources; `[AiTool]`, npm CLI, batchmode and in-Player; project path must not contain spaces, still in the README) > CoderGamester/mcp-unity (MIT, ~1.9k, v1.5.0 on 2026-09-03 still the latest tag on 2026-10-17, community PRs merged 2026-10-11; a required per-project token in `Library/McpUnity/bridge-token`, WebSocket 8090, Unity 6+). None is in the official MCP registry; a registry search for `unity` returns Funplay's small bridge, a docs server (unity-api-mcp) and a paid test-loop server.
- Docs: CLI beta.11 adds `unity docs <topic>` (docs matched to the project's Unity version) and Unity's remote Issue Tracker MCP (`unity mcp configure <client> --server issue-tracker`). docs.unity.com publishes an `llms.txt`; docs.unity3d.com has none. saqoosha/unity-docs-mcp is unmaintained (12 stars, last push 2025-06); Codeturion/unity-api-mcp (MCP registry) is the maintained community docs server.
- Pitfalls verified from issues and reports: bridges drop on domain reload (CoplayDev #657, #1207; 20 s reconnect), forced DisableDomainReload for PlayMode tests causes NRE after an EditMode run (#1322), Windows TcpListener leak with silent port fallback (#1173), unfocused Editor stops ticking, modal dialogs need `-automated`, Pipeline token 401 after Play mode reported by Vindler (docs say the token survives reloads within a session). Unity 6000.5.1 + Assistant 2.13.0-pre.2 livelocks the AssetDatabase at startup (UUM-132096, CoplayDev #1219). Unity 6000.6 broke CoplayDev v10.2.0's instance-ID lookups (#1398, #1412; fix #1399 on `main` 2026-09-30, unreleased); the Save/Reload-scene prompt stalls agents that read it as an import (#1411).
- Practice consensus (Unity Discussions, 2026): code-only work is the most reliable; MCP is best for inspection and small scene edits; hand-emitting YAML is unreliable. Robert Wetzold migrated 31 MCP tools to `[CliCommand]`s in Aug 2026 (secondary source).
- Nothing installed on the development machine as of 2026-09-06: no `~/.claude.json` MCP entries for Unity, no Pipeline package in the game project, so no bridge is verified locally.

## Open questions

- (resolved 2026-10-11) CoplayDev v10.3.0 ships the 6000.6 fix (#1399).
- (partly resolved 2026-10-23) Pipeline 0.9.0 shipped 2026-10-20 with no command aliases; beta.14's `--tools` filters accept old names, but the exact MCP tool identifier after grouping is undocumented: verify with a `tools/list` probe when an Editor is free (R-20261023-1, R-20261023-3).
- (resolved 2026-10-23) IvanMurzak 1.x: about 60 named tools plus RQL sources (R-20261023-4).
- When is IN-158307 (Editor fails to restart under Pipeline 0.9 on Windows) fixed for 6000.5 below 5.11f1? Does Unity's plugin page switch to the `claude-plugins-official` route? (R-20261023-2, R-20261023-3)
- Which Unity 7 alpha carries the Mono.Cecil/MSBuild fix that lets Pipeline build (a10 hung; a11 with Pipeline 0.9 logs IN-158363 errors; staff say 7.0 daily builds connect)? (R-20261017-2, R-20261023-2)
- Which client is best served by `unity mcp` versus the CLI in practice (latency per call was reported around 0.8 s). Footprint measured 2026-09-06: 149 tools, ~24k tokens of schema.
- Does CoplayDev v10.1.x list Unity 6.5/6.6 as tested (the 6.5 fix was in 9.6.8)?
- (partly resolved 2026-09-22) Unity 6.6 shipped 2026-09-01 with Play entry skipping the domain reload by default in new projects only; existing projects keep their setting. Do the reload pitfalls shrink for bridges on those projects?
- Which scope does `unity mcp configure claude-code` write? Does the Issue Tracker MCP need a sign-in, and which tools does it expose?
- Will Unity list `unity mcp` in the official MCP registry?

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `unity mcp configure` and `com.unity.pipeline` docs (docs.unity3d.com package manual); `unity changelog` offline
- `docs.unity3d.com/Packages/com.unity.ai.assistant@<latest>/manual/integration/unity-mcp-get-started.html` (watch for un-deprecation); `https://packages.unity.com/com.unity.ai.assistant` and `https://packages.unity.com/com.unity.pipeline` (`dist-tags`, `time`) for the newest versions; the Assistant changelog at `docs.unity3d.com/Packages/com.unity.ai.assistant@<major.minor>/changelog/CHANGELOG.html`
- Official forum and announcements (staff posts are primary): the product-update category feed `https://discussions.unity.com/c/unity-editor/product-update/205.json` (works with WebFetch; fastest way to find Pipeline and CLI announcement topics); the Pipeline package changelog `docs.unity3d.com/Packages/com.unity.pipeline@<major.minor>/changelog/CHANGELOG.html`; the CLI release-notes page is about 370k characters and truncates, so ask for one version; `https://docs.unity.com/en-us/unity-cli/release-notes`; the Pipeline 0.9.0 heads-up thread `https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559` (until the upgrade post lands); `site:discussions.unity.com "unity cli" OR pipeline OR mcp <month year>`; unity.com/blog for AI Assistant and MCP announcements. The forum's `search.json` and `/c/.../latest.json` endpoints refuse plain curl and WebFetch (2026-10-14); fetch a topic as `<topic url>.json` instead, and later posts of a long thread as `<topic url>/<post number>.json`; the Unity 7 alpha thread `https://discussions.unity.com/t/unity-7-0-alpha-is-now-available/1738310` for reload and Pipeline-on-7 news

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; github.com/CoplayDev/unity-mcp/releases (and `gh api repos/CoplayDev/unity-mcp/commits?since=<last_checked>`, since fixes sit on `main` for weeks between releases); github.com/IvanMurzak/Unity-MCP/releases (each release now ships about 10 add-on tags, so `releases?per_page=12` shows one main release; read per-tag pages `/releases/tag/<v>`); Unity's `skills/unity-cli/references/integration-advanced.md` for `unity mcp` filter semantics; github.com/CoderGamester/mcp-unity/commits/main; `api.github.com/repos/Unity-Technologies/skills/commits?path=skills/unity-pipeline`
- skills.sh installs (`https://skills.sh/api/search?q=unity`): `unity-cli`, `unity-pipeline`, CoplayDev `unity-mcp-orchestrator`
- `path:SKILL.md "unity-mcp" OR "unity mcp"` on GitHub code search; `unity mcp server <year> site:github.com stars:>500`

Practice (how others use AI agents on this goal, and everything in between):

- `site:discussions.unity.com mcp claude code OR cursor <year>`; hn.algolia.com `unity mcp` sorted by date; vindler.solutions
- `"unity-mcp" "domain reload" issue <year>`

Testing (how the job is verified and what checkers exist):

- `claude mcp list unity connected`; `"mcp inspector" unity`; CoplayDev `run_tests` tool docs; `unity command get_console_logs` as verification
- `GameDevBench` and follow-ups for agent-on-Editor evaluation; tessl.io registry evals pages for Unity MCP skills (lead, unread)

Best sources (primary first): the three GitHub repos (README, releases, issues), docs.unity3d.com package manuals, unity.com/blog, the MCP registry API. Noisy: mcpservers.org, glama listings without dates, YouTube.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20261030-1 · 2026-10-30 · Subject: Unity CLI 1.0.0-beta.15
- track: subject. magnitude: 0.4. applied: C-20261030-1
- Staff post 2026-10-29: unique MCP tool names (`settings_player_get`, `script_eval`), MCP job tools, `unity mcp --cli-tools`, `unity list` and `list` subcommands removed, JSON listings now `items/total/nextPage/partial`, `cli.version` pin in `ProjectSettings/UnityCliConfig.json`, `unity command` uses the Pipeline connection with HTTP fallback.
- sources: https://discussions.unity.com/t/unity-cli-1-0-0-beta-15-is-rolling-out/1740651

### R-20261030-2 · 2026-10-30 · Rest quiet
- Pipeline still 0.9.1-exp.1; Assistant 2.21.0-pre.2 (10-26), no MCP change found. CoplayDev v10.3.0 still latest; IvanMurzak 1.5.0 (10-24, already noted); CoderGamester 1.5.0. Practice: nothing new. Testing: nothing new. Unity 7.0 planned breaking changes (10-22) affect headless more than MCP.

### R-20261023-1 · 2026-10-23 · Subject: Pipeline 0.9.0-exp.1 shipped; 0.9.1-exp.1 is latest
- Summary: packages.unity.com: 0.9.0-exp.1 (2026-10-20) and 0.9.1-exp.1 (2026-10-23, dist-tag `latest`), verified with curl. 0.9.0 groups commands (`unity command <group> <name>`, such as `editor status`, `script eval`, `test run`) and removes the old flat names; Code Reload becomes Method Reload; `[CliCommand]` takes the group first; `RuntimeOnly` and `dialogsDuringExecution` removed; requests whose Host is not 127.0.0.1 are refused (DNS rebinding); new Build Profile commands and `editor_set_run_in_background`. 0.9.1 reads a dotted `[CliCommand]` name as group.name and fixes the Android/iOS Subtarget pre-build exception and Unity 7 analyzer warnings. Upgrade: `unity pipeline install --package-version 0.9.0-exp.1 --force`.
- Track: subject
- Sources: https://packages.unity.com/com.unity.pipeline, https://docs.unity3d.com/Packages/com.unity.pipeline@0.9/changelog/CHANGELOG.html, https://discussions.unity.com/t/unity-pipeline-package-0-9-0-exp-1-is-available-now/1739888.json
- Magnitude: 0.6 (the official row's version and "announced, no date" were wrong)
- Applied: C-20261023-1

### R-20261023-2 · 2026-10-23 · Practice: the 0.9 rollout breaks things; pair with CLI beta.14 and check the Editor patch
- Summary: In the announcement thread: IN-158307, the Editor fails to restart on Windows with an AssetDatabase "restricted during code reload" error (staff reproduced on 6000.5.2f1; fixed in 6000.5.11f1+); IN-158369 Android Build and Run Subtarget exception (fixed in 0.9.1); IN-158363 Unity 7000.0.0a11 logs 15 errors for render-pipelines.core command names with dots; CLI beta.13 sends old names that 0.9 rejects (staff: use beta.14); a downgrade to 0.7.0 on a11 hit "No available ports in range 7800-7849". Staff called the release "riskier than usual". Response: adopt (Step 4 pitfall, eval case outcome-2).
- Track: practice
- Sources: https://discussions.unity.com/t/unity-pipeline-package-0-9-0-exp-1-is-available-now/1739888.json, https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559.json
- Magnitude: 0.45
- Applied: C-20261023-1

### R-20261023-3 · 2026-10-23 · Subject and tooling: CLI beta.14 adds MCP tool filters and Editor pinning
- Summary: Unity CLI 1.0.0-beta.14 (2026-10-21): `unity mcp --tools` / `--exclude-tools` (comma-separated, `*` wildcard, case-sensitive) limit the exposed tools; patterns match a command under its grouped dotted name (`script.eval`) and its old flat name (`eval`, `run_tests`); hidden tools are refused with the list of exposed ones; `unity-cli-status` is never hidden. `unity mcp`, `command`, `list`, `job` take `--port`, `--pid`, `--instance`; inside a project with no Editor open they no longer reach another project's Editor. `unity mcp configure` quotes paths with spaces and fixes empty `--format json`. `unity setup claude` installs `unity@claude-plugins-official`; Unity's plugin page still shows `unity@unity-agent-plugin`. `unity projects create` adds the Pipeline by default. Response: adopt (Step 1 rung 3 footprint, Step 3.3 register command, Step 4 two Editors).
- Track: subject, tooling
- Sources: https://docs.unity.com/en-us/unity-cli/release-notes, https://discussions.unity.com/t/unity-cli-1-0-0-beta-14-is-rolling-out/1739999.json, https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-cli/references/integration-advanced.md, https://docs.unity.com/en-us/ai/unity-plugin/claude-code
- Magnitude: 0.5
- Applied: C-20261023-1

### R-20261023-4 · 2026-10-23 · Tooling: IvanMurzak 1.2.0 to 1.5.0; CoplayDev quiet; adoption; testing quiet
- Summary: IvanMurzak 1.2.0 (10-18, account token to loopback only), 1.3.0 (10-20, CLI `exec`, headless `open` with idle shutdown), 1.4.0 (10-22, Lighting RQL module, Unity 7 CoreCLR startup-hang fix), 1.5.0 (10-24 UTC, standalone CLI/App skills; tests-run lock holds until the run ends); add-ons 2.0.2; README still forbids spaces in the project path and says 70+ tools while listing about 60; 4,521 stars. CoplayDev still v10.3.0 (`main` 10.3.1-beta.11: `read_console` log-type fix, Windows UTF-8; PR #1463 open; 15,362 stars). CoderGamester unchanged (1.5.0). MCP registry unchanged. skills.sh: `unity-cli` 8,365 (+569 in 6 days), `unity-pipeline` 1,028 (from 538), `unity-mcp-orchestrator` 428. unity-agent-plugin 0.1.8-beta, no MCP server. Practice: HN nothing relevant. Testing: no Unity agent benchmark; a self-reported CoplayDev facade ("Unity MCP Efficient", Glama) claims about 23k to 915 schema tokens, unread. Response: point (IvanMurzak row), note otherwise.
- Track: tooling, practice, testing
- Sources: https://github.com/IvanMurzak/Unity-MCP/releases/tag/1.3.0, https://raw.githubusercontent.com/IvanMurzak/Unity-MCP/main/README.md, https://api.github.com/repos/CoplayDev/unity-mcp/commits?since=2026-10-17T00:00:00Z&per_page=50, https://skills.sh/api/search?q=unity, https://glama.ai/mcp/servers/ia088l2cr7
- Magnitude: 0.2
- Applied: C-20261023-1

### R-20261017-1 · 2026-10-17 · Tooling: IvanMurzak Unity-MCP 1.0.0 replaces the data tools with RQL; 1.1.0 splits the add-ons
- Summary: 1.0.0 (2026-10-15) has two breaking commits: "RQL replaces the data tools and is the tools' data layer" (#1017) and "profiler tools become the RQL profiler source" (#1018); no migration notes. 1.0.1 (2026-10-16) fixes lost main-thread dispatches from background threads (flaky timeouts), a cold test-tree timeout in tests-run and which Editor the CLI closes. 1.1.0 (2026-10-17) moves the add-ons (Animation, Cinemachine, InputSystem, Navigation, ParticleSystem, ProBuilder, Splines, Terrain, Tilemap, Timeline) into their own signed UPM packages at 2.0.1. 4,489 stars. The README still says the project path cannot contain spaces (checked 2026-10-17). New tool count unverified. Response: point (row updated with the upgrade warning).
- Track: tooling
- Sources: https://github.com/IvanMurzak/Unity-MCP/releases/tag/1.0.0, https://api.github.com/repos/IvanMurzak/Unity-MCP/releases?per_page=12, https://github.com/IvanMurzak/Unity-MCP
- Magnitude: 0.35 (a tool's names and count changed under an upgrade)
- Applied: C-20261017-1

### R-20261017-2 · 2026-10-17 · Subject: Pipeline on Unity 7 waits for an Editor alpha; Unity 7 reload is an AssemblyLoadContext reload
- Summary: In the 0.9.0 heads-up thread staff (2026-10-15) said the Mono.Cecil block that stops Pipeline 0.8 building on Unity 7 MSBuild projects "will be fixed in the next version of Unity 7"; a user reported 7000.0.0a10 still hanging (2026-10-16), no staff reply yet. In the Unity 7 alpha thread staff (2026-10-14) confirmed the domain reload is replaced by an AssemblyLoadContext-based reload on .NET 10.
- Track: subject
- Sources: https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559.json, https://discussions.unity.com/t/unity-7-0-alpha-is-now-available/1738310/96.json
- Magnitude: 0.15
- Applied: C-20261017-1

### R-20261017-3 · 2026-10-17 · Tooling, subject, practice, testing: Unity's `unity-pipeline` skill; otherwise quiet
- Summary: Unity-Technologies/skills added `skills/unity-pipeline` (#114, 2026-10-08): drives a running Editor or dev Player with `unity command <name>` (readiness, ticking, recompiles, tests, `run_script`, `eval`, Project Auditor; ports 7800-7849 Editor, 7900-7949 Player); no MCP tools. skills.sh installs: `unity-cli` 7,796 (about +290 in 3 days), `unity-pipeline` 538, CoplayDev `unity-mcp-orchestrator` 411. Response: point (Step 1 rung 2). Quiet otherwise: `com.unity.pipeline` still 0.8.0-exp.1, 0.9.0 unshipped with no date or alias word; CLI release notes end at beta.13; `com.unity.ai.assistant` 2.20.0-pre.2; unity-agent-plugin 0.1.8-beta, no `.mcp.json`; CoplayDev v10.3.0 latest (`main` 10.3.1-beta.8 with #1472; Play Mode wait PR #1463 still open; 15,054 stars); CoderGamester 1.5.0, no commits; MCP registry unchanged. Practice: nothing new. Testing: nothing new (GameDevBench remains the nearest general benchmark; a tessl.io evals page for IvanMurzak's tests-run skill is a lead).
- Track: tooling, subject, practice, testing
- Sources: https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-pipeline/SKILL.md, https://skills.sh/api/search?q=unity, https://packages.unity.com/com.unity.pipeline, https://docs.unity.com/en-us/unity-cli/release-notes, https://packages.unity.com/com.unity.ai.assistant, https://api.github.com/repos/CoplayDev/unity-mcp/commits?since=2026-10-14T00:00:00Z, https://api.github.com/repos/CoplayDev/unity-mcp/pulls/1463, https://api.github.com/repos/CoderGamester/mcp-unity/tags, https://registry.modelcontextprotocol.io/v0/servers?search=unity&limit=100, https://tessl.io/registry/skills/github/IvanMurzak/Unity-MCP/tests-run/evals
- Magnitude: 0.2
- Applied: C-20261017-1

### R-20261014-1 · 2026-10-14 · Quiet check: nothing released that changes a claim
- Summary: Subject: `com.unity.pipeline` still 0.8.0-exp.1 (packages.unity.com); CLI release notes still end at 1.0.0-beta.13 (2026-10-07); the Pipeline 0.9.0 heads-up thread has no date, no rename list and no word on MCP tool aliases, and its last staff reply (2026-10-09) calls the Unity 7 Mono.Cecil block "high priority", unfixed so far. `com.unity.ai.assistant` 2.20.0-pre.2 (2026-10-06) only fixes a CoreCLR crash on 7000.0; nothing on MCP. No new Unity AI or MCP announcement found on discussions.unity.com or unity.com/blog since 2026-10-11. Tooling: CoplayDev v10.3.0 still latest (14,940 stars; about 18 open PRs since 2026-10-11, among them Play Mode startup wait #1463, prefab overrides #1462, a no-session recovery hint #1470); IvanMurzak 0.93.4 (2026-10-13, docs only: AGENTS.md); CoderGamester no tag after 1.5.0 (PRs #164, #166 merged 2026-10-11); MCP registry still has no Unity, CoplayDev or CoderGamester entry (Codeturion unity-api-mcp 2.1.1, Funplay 0.7.0); skills.sh `unity-cli` about 7,506 installs; unity-agent-plugin 413 stars. Practice: nothing new. Testing: nothing new (no Unity-specific agent benchmark; general MCP benchmarks only).
- Track: subject, tooling, practice, testing
- Sources: https://packages.unity.com/com.unity.pipeline, https://packages.unity.com/com.unity.ai.assistant, https://docs.unity.com/en-us/unity-cli/release-notes, https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559, https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.20/changelog/CHANGELOG.html, https://github.com/CoplayDev/unity-mcp/pulls, https://github.com/IvanMurzak/Unity-MCP/releases/tag/0.93.4, https://github.com/CoderGamester/mcp-unity/commits/main, https://registry.modelcontextprotocol.io/v0/servers?search=unity&limit=100, https://skills.sh/api/search?q=unity
- Magnitude: 0.1
- Applied: C-20261014-1 (RESEARCH.md only; SKILL.md unchanged)

### R-20261011-1 · 2026-10-11 · Subject: Pipeline 0.9 renames commands; CLI beta.13 dialog status and UNITY_PROJECT_PATH; Unity 7 alpha
- Summary: Unity's heads-up (2026-10-07) says `com.unity.pipeline` 0.9.0 renames many commands with no aliases (an old name answers 400 "Command Not Found"; `unity command --obsolete-command-names` lists the mapping); no date, 0.8.0-exp.1 still latest. `unity mcp` tool names mirror command names, so client allow-lists and evals naming tools break. CLI 1.0.0-beta.13: `unity mcp` reads `UNITY_PROJECT_PATH` when `--project-path` is omitted; `unity status` reports `STATUS_BLOCKED_BY_DIALOG` with `blockedBy`; `unity setup codex` and `unity setup grok` install Unity's agent plugin (0.1.8-beta, 404 stars). Unity 7.0 public alpha (2026-10-05): CoreCLR only, code reloads replace domain reloads (thread reply); Pipeline 0.8 blocks MSBuild projects on Unity 7 through Mono.Cecil ("high priority", 10-09); Assistant 2.20.0-pre.2 fixed a crash on 7000.0. ToS section 17.2 "Authorized Agentic Access" covers cloud services per Unity's informal reply; local Editor MCP is fine.
- Track: subject, practice
- Sources: https://discussions.unity.com/t/heads-up-upcoming-com-unity-pipeline-0-9-0-release-will-include-breaking-changes-to-command-names/1738559, https://packages.unity.com/com.unity.pipeline, https://docs.unity.com/en-us/unity-cli/release-notes, https://discussions.unity.com/t/unity-7-0-alpha-is-now-available/1738310, https://unity.com/releases/editor/alpha/7000.0.0a7
- Magnitude: 0.5 (an upgrade will break tool names)
- Applied: C-20261011-1 (SKILL.md Step 2 official row; Step 4 pitfalls)

### R-20261011-2 · 2026-10-11 · Tooling and testing: CoplayDev v10.3.0 fixes 6000.6; versions and adoption; no new checker
- Summary: CoplayDev v10.3.0 (2026-10-04, 14,842 stars) ships #1399 (the 6000.6 `InstanceIDToObjectCompat` fix) plus Claude Code registrations in CheckStatus, a Blender Bridge and new configurators. IvanMurzak 0.93.3 (2026-10-10, console `sinceSequence` cursor, 4,418 stars). CoderGamester merging PRs again since 2026-10-11, no tag after 1.5.0. skills.sh: CoplayDev `unity-mcp-orchestrator` about 394 installs against 7,286 for Unity's `unity-cli`. The MCP registry has an old IvanMurzak 0.17.1 entry, none for Unity, CoplayDev or CoderGamester. Testing: no new Editor-bridge checker; CraftBench-UE (Unreal) and OpenGameEval (Roblox) do not cover Unity.
- Track: tooling, testing
- Sources: https://github.com/CoplayDev/unity-mcp/releases, https://github.com/IvanMurzak/Unity-MCP/releases, https://github.com/CoderGamester/mcp-unity/commits/main, https://skills.sh/api/search?q=unity-mcp, https://registry.modelcontextprotocol.io/v0/servers?search=unity&limit=100, https://arxiv.org/pdf/2609.23142
- Magnitude: 0.3
- Applied: C-20261011-1 (SKILL.md Step 2 CoplayDev row and registry note)

### R-20261003-3 · 2026-10-03 · Practice and testing: quiet beyond Unity's play-mode loop
- summary: No new practitioner write-ups on MCP versus CLI since 2026-09-22 beyond Unity's own play-mode verification loop (CLI-based: `status --until-ready`, `wait_for` on `Time.frameCount`; see unity-agent-cli R-20261003-2), which reinforces rung 2 for clients with a shell. Testing: nothing new for Editor bridges (general MCP benchmarks such as MCP-AgentBench are not Unity-specific). The MCP registry still lists no Unity Technologies server; its Unity entries are community bridges (Funplay, shiranui-isuzu 4.4.2, hera-agent-unity) and the Codeturion docs server.
- track: practice, testing
- sources: https://raw.githubusercontent.com/Unity-Technologies/skills/main/skills/unity-cli/references/playmode-verification-loop.md, https://registry.modelcontextprotocol.io/v0/servers?search=unity&limit=100
- magnitude: 0.1
- applied: note

### R-20261003-2 · 2026-10-03 · Tooling: server versions and the Unity 6000.6 break in CoplayDev
- summary: CoplayDev 14.7K stars, no release since v10.2.0 (2026-09-01) but busy `main`: #1399 (merged 2026-09-30) fixes `InstanceIDToObjectCompat` throwing `NotImplementedException` on 6000.6, which broke `manage_components` and the `gameobject/{id}` resources (#1398, #1412 still open on 6000.6.2f1); a Pi client configurator; Unity.Mathematics serialisation fix for a hang (#1415). #1411: agents stall on the Save/Reload-scene dialog, taking it for an import. IvanMurzak 0.92.0 to 0.93.2 (2026-09-23 to 27): CLI setup fixes, a 6000.6.3f1 test project. CoderGamester unchanged since 1.5.0. Response: point (CoplayDev row note, Step 4 dialog bullet).
- track: tooling
- sources: https://github.com/CoplayDev/unity-mcp/pull/1399, https://github.com/CoplayDev/unity-mcp/issues/1412, https://github.com/CoplayDev/unity-mcp/issues/1411, https://github.com/IvanMurzak/Unity-MCP/releases, https://github.com/CoderGamester/mcp-unity/releases
- magnitude: 0.3
- applied: C-20261003-1

### R-20261003-1 · 2026-10-03 · Subject: CLI beta.12 de-duplicates the Claude Code entry, safer Codex config, `unity bug mcp`
- summary: CLI 1.0.0-beta.12 (2026-09-30): `unity mcp configure claude-code` checks whether an enabled Claude Code plugin already provides a server running `unity mcp` for the same project and then warns and skips its own `claude mcp add` unless confirmed or `--yes`; `unity mcp configure codex` refuses to edit `config.toml` when it cannot verify a safe match; `unity bug mcp` is an alias of `unity mcp configure --server issue-tracker` (same `--list`, `--local`, `--yes`, `--dry-run`); `unity mcp` treats an Editor argument error as an answer, not a lost connection; `unity setup claude` installs Unity's plugin (no MCP server in it, 0.1.8-beta). Pipeline unchanged at 0.8.0-exp.1.
- track: subject
- sources: https://docs.unity.com/en-us/unity-cli/release-notes, https://github.com/Unity-Technologies/unity-agent-plugin, https://packages.unity.com/com.unity.pipeline
- magnitude: 0.3
- applied: C-20261003-1

### R-20260922-6 · 2026-09-22 · Testing: the MCP Inspector CLI proves a server's tools without any client
- summary: `npx @modelcontextprotocol/inspector --cli <server command> --method tools/list` returns the tool list as JSON, and `--method tools/call --tool-name <name>` makes one call, so a stdio server such as `unity mcp` can be verified for clients with no status command. Response: adopt, as the Step 3 evidence and a new action case.
- track: testing
- sources: https://modelcontextprotocol.io/docs/2026-07-28/tools/inspector
- magnitude: 0.3
- applied: C-20260922-2 (SKILL.md Step 3 verify; evals action-2)

### R-20260922-5 · 2026-09-22 · Tooling: adoption baseline (the first install snapshot)
- summary: skills.sh installs: Unity-Technologies `unity-cli` ~5.8K, CoplayDev `unity-mcp-orchestrator` ~370. Stars: CoplayDev ~14.4K, IvanMurzak ~4.3K, CoderGamester ~1.9K (flat; three community PRs unreviewed since 2026-09-03), Unity-Technologies/skills ~950, unity-agent-plugin ~330. The converged view (Unity's replace-MCP page, Unity's CLI-first plugin, a community server's own move to a CLI): with a shell, direct CLI commands beat MCP; MCP serves clients without one. The ranking in SKILL.md holds; velocity needs the next snapshot.
- track: tooling
- sources: https://skills.sh/api/search?q=unity, https://docs.unity.com/en-us/unity-cli/replace-mcp-server-unity-cli, https://github.com/CoplayDev/unity-mcp
- magnitude: 0.2
- applied: note only

### R-20260922-4 · 2026-09-22 · Subject: Unity's official Claude Code plugin is CLI-first and registers no MCP server
- summary: Unity-Technologies/unity-agent-plugin (0.1.6-beta; `/plugin install unity@unity-agent-plugin`) ships Unity's skills, `unity-cli` among them; its root has no `.mcp.json`, and Unity's announcement does not mention MCP (trade-press claims of a bundled MCP server are wrong).
- track: tooling
- sources: https://unity.com/blog/unity-plugin-for-claude-code, https://github.com/Unity-Technologies/unity-agent-plugin
- magnitude: 0.45
- applied: C-20260922-2 (SKILL.md Step 1 rung 2)

### R-20260922-3 · 2026-09-22 · Subject: `unity mcp configure claude-code` exists; register Claude Code at local scope
- summary: Unity's skill reference (aligned to beta.10) lists 16 client ids for `unity mcp configure`: claude, claude-code, cursor, vscode, vscode-insiders, copilot-cli, windsurf, cline, codex, kiro, trae, openclaw, antigravity, zed, continue, inspect; `--local` only for some; `--dry-run` prints just the entry. The Step 3 wording "user scope, one project pinned" contradicted Step 1's local-scope rule.
- track: subject
- sources: https://github.com/Unity-Technologies/skills/blob/main/skills/unity-cli/references/integration-advanced.md, https://code.claude.com/docs/en/mcp
- magnitude: 0.3
- applied: C-20260922-2 (SKILL.md Step 2 official row, Step 3.3; evals outcome-1)

### R-20260922-2 · 2026-09-22 · Practice: CoplayDev tool groups hide `run_tests`; a tool's success is not the Editor's state
- summary: CoplayDev ships 47 tools in groups and enables only `core` by default, so `run_tests` stays hidden until the `testing` group is activated (its bundled orchestrator skill added this on 2026-09-19). Issues since the last check: `manage_editor play` returned success while Unity cancelled Play (#1379), the Editor window showed "Not Configured" while the client listed 48 tools (#1397), a focus loop (#1407, fix pending in #1410).
- track: practice
- sources: https://coplaydev.github.io/unity-mcp/guides/tool-groups, https://github.com/CoplayDev/unity-mcp/issues/1379, https://github.com/CoplayDev/unity-mcp/issues/1397, https://github.com/CoplayDev/unity-mcp/pull/1410
- magnitude: 0.3
- applied: C-20260922-2 (SKILL.md Step 2 CoplayDev row, Step 4 new bullet)

### R-20260922-1 · 2026-09-22 · Subject: Pipeline 0.7, CLI beta.9 to beta.11, and server versions
- summary: Pipeline 0.7.0-exp.1 (2026-09-10) removed `get_console_logs` in favour of `console`. CLI beta.9 stopped passing numeric and array tool parameters as strings over `unity mcp`; beta.10 made captures fall back to a whole-desktop screenshot when the Editor is blocked; beta.11 added `unity docs` and `unity mcp configure --server issue-tracker`. IvanMurzak 0.91.0 (2026-09-17; the no-spaces path rule stands). CoderGamester 1.5.0 requires a per-project token (`MCP_UNITY_AUTH_TOKEN`, `MCP_UNITY_AUTH_TOKEN_PATH` or `Library/McpUnity/bridge-token`). The MCP registry lists no `unity mcp` entry; its Unity entries are small community bridges. Unity 6.6 (2026-09-01) skips the domain reload on Play entry by default in new projects (secondary sources).
- track: subject
- sources: https://docs.unity3d.com/Packages/com.unity.pipeline@0.7/changelog/CHANGELOG.html, https://docs.unity.com/en-us/unity-cli/release-notes, https://discussions.unity.com/t/unity-cli-1-0-0-beta-11-is-rolling-out/1737353, https://github.com/IvanMurzak/Unity-MCP/releases, https://github.com/CoderGamester/mcp-unity/releases, https://registry.modelcontextprotocol.io/v0/servers?search=unity&limit=100, https://openupm.com/blog/unity-66-fast-enter-play-mode-package-readiness/
- magnitude: 0.35
- applied: C-20260922-2 (SKILL.md Step 2 table and registry note, Step 4 reload bullet)

### R-20260906-4 · 2026-09-06 · Measured `unity mcp` footprint: 149 tools, ~96 KB schema (~24k tokens)
- Summary: With Pipeline 0.6.0-exp.1 reachable, a stdio `tools/list` against `unity mcp --project-path <project>` (CLI 1.0.0-beta.8) returned 149 tools totalling 96,012 bytes of JSON schema, about 24k tokens if a client loads every schema up front; with no reachable Editor the same server returns 0 tools. Claude Code (2.1.2xx) defers MCP tool schemas behind ToolSearch, so the standing cost is the name list; Claude Desktop and Cursor load schemas eagerly. Registered at local scope for that one project only (`claude mcp add --scope local`), so other projects pay nothing; the CLI route exposes the same 149 commands at zero context cost.
- Track: testing
- Sources: local MCP stdio probe 2026-09-06; `claude mcp get unity`
- Magnitude: 0.3 (a concrete number for the CLI-vs-MCP decision)
- Applied: C-20260906-2

### R-20260906-3 · 2026-09-06 · Pitfalls from issues and field reports
- Summary: CoplayDev issues #657/#1207 (reload drops bridge), #1322 (PlayMode test NRE), #1173 (TcpListener leak), #1219 (6000.5.1 + Assistant 2.13-pre livelock, UUM-132096); Vindler 2026-07-22 (token 401 after Play mode, `-automated`, focus); HN thread on screenshot-loop unreliability. Applied as the pitfalls section.
- Track: practice
- Sources: https://github.com/CoplayDev/unity-mcp/issues/1219, https://github.com/CoplayDev/unity-mcp/issues/1322, https://github.com/CoplayDev/unity-mcp/issues/1173, https://github.com/CoplayDev/unity-mcp/issues/657, https://vindler.solutions/blog/unity-cli-agent-automation, https://news.ycombinator.com/item?id=48995712
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-2 · 2026-09-06 · Community server ranking and registry state
- Summary: CoplayDev (~13.9k stars, v10, Unity 2021.3-6.5, 47 tools), IvanMurzak (~4.2k, 0.89.0, 70+ tools, no spaces in project path), CoderGamester (~1.9k, 1.5.0 on 2026-09-02). Official MCP registry has no major Unity server. No official docs MCP; saqoosha/unity-docs-mcp community.
- Track: tooling
- Sources: https://github.com/CoplayDev/unity-mcp, https://coplaydev.github.io/unity-mcp/releases, https://github.com/IvanMurzak/Unity-MCP/releases, https://github.com/CoderGamester/mcp-unity, https://registry.modelcontextprotocol.io/v0/servers?search=unity, https://lobehub.com/mcp/saqoosha-unity-docs-mcp
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Official `unity mcp` replaces the Assistant's in-Editor MCP
- Summary: Unity CLI (2026-07-20) ships `unity mcp` and `unity mcp configure`; Assistant 2.18 docs deprecate the in-Editor server; the May 2026 Assistant MCP needed Unity Cloud and an AI beta seat. `unity mcp configure --list` verified locally with 17 clients.
- Track: subject
- Sources: https://unity.com/blog/meet-the-unity-cli, https://docs.unity3d.com/Packages/com.unity.ai.assistant@2.18/manual/integration/unity-mcp-get-started.html, https://unity.com/blog/unity-ai-mcp-how-to-get-started, local `unity mcp configure --list` 2026-09-06
- Magnitude: n/a (initial)
- Applied: C-20260906-1
