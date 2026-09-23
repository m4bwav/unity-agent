# Research: unity-agent-mcp

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: MCP servers that bridge AI agents to the Unity Editor: Unity's official unity mcp mode, CoplayDev, IvanMurzak, CoderGamester, docs servers; client configuration and domain-reload pitfalls. Tier `fast`. Last refresh 2026-09-22; next due per `evergreen.json`.

## Current understanding

- Official route (since July 2026): the Unity CLI's `unity mcp` stdio server over `com.unity.pipeline` (0.7.0-exp.1 since 2026-09-10; Unity 6.0+). Free, no Unity AI subscription. `unity mcp configure <client>` writes the config for 16 client ids (beta.10), `claude-code` included (`--dry-run` previews); `claude mcp add --scope local` stays the manual route. Unity's official Claude Code plugin (2026-09-09) is CLI-first and registers no MCP server. The older in-Editor "Unity MCP" (com.unity.ai.assistant 2.x, relay in `~/.unity/relay/`, needs Unity Cloud plus an AI beta seat) is marked deprecated in Assistant 2.18 docs.
- Community ranking by adoption (stars, last commit): CoplayDev/unity-mcp (MIT, ~14.4k stars, v10.2.0 on 2026-09-01; Unity 2021.3 to 6.5; 47 tools in groups, only `core` on by default; Python/uv server) > IvanMurzak/Unity-MCP (Apache-2.0, ~4.3k, 0.91.0 on 2026-09-17; 70+ tools, `[AiTool]`, npm CLI, batchmode and in-Player; project path must not contain spaces) > CoderGamester/mcp-unity (MIT, ~1.9k, v1.5.0 on 2026-09-03 with a required per-project token in `Library/McpUnity/bridge-token`, WebSocket 8090, Unity 6+). None is in the official MCP registry; a registry search for `unity` returns Funplay's small bridge, a docs server (unity-api-mcp) and a paid test-loop server.
- Docs: CLI beta.11 adds `unity docs <topic>` (docs matched to the project's Unity version) and Unity's remote Issue Tracker MCP (`unity mcp configure <client> --server issue-tracker`). docs.unity.com publishes an `llms.txt`; docs.unity3d.com has none. saqoosha/unity-docs-mcp is unmaintained (12 stars, last push 2025-06); Codeturion/unity-api-mcp (MCP registry) is the maintained community docs server.
- Pitfalls verified from issues and reports: bridges drop on domain reload (CoplayDev #657, #1207; 20 s reconnect), forced DisableDomainReload for PlayMode tests causes NRE after an EditMode run (#1322), Windows TcpListener leak with silent port fallback (#1173), unfocused Editor stops ticking, modal dialogs need `-automated`, Pipeline token 401 after Play mode reported by Vindler (docs say the token survives reloads within a session). Unity 6000.5.1 + Assistant 2.13.0-pre.2 livelocks the AssetDatabase at startup (UUM-132096, CoplayDev #1219).
- Practice consensus (Unity Discussions, 2026): code-only work is the most reliable; MCP is best for inspection and small scene edits; hand-emitting YAML is unreliable. Robert Wetzold migrated 31 MCP tools to `[CliCommand]`s in Aug 2026 (secondary source).
- Nothing installed on the development machine as of 2026-09-06: no `~/.claude.json` MCP entries for Unity, no Pipeline package in the game project, so no bridge is verified locally.

## Open questions

- Which client is best served by `unity mcp` versus the CLI in practice (latency per call was reported around 0.8 s). Footprint measured 2026-09-06: 149 tools, ~24k tokens of schema.
- Does CoplayDev v10.1.x list Unity 6.5/6.6 as tested (the 6.5 fix was in 9.6.8)?
- (partly resolved 2026-09-22) Unity 6.6 shipped 2026-09-01 with Play entry skipping the domain reload by default in new projects only; existing projects keep their setting. Do the reload pitfalls shrink for bridges on those projects?
- Which scope does `unity mcp configure claude-code` write? Does the Issue Tracker MCP need a sign-in, and which tools does it expose?
- Will Unity list `unity mcp` in the official MCP registry?

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `unity mcp configure` and `com.unity.pipeline` docs (docs.unity3d.com package manual); `unity changelog` offline
- `docs.unity3d.com/Packages/com.unity.ai.assistant@<latest>/manual/integration/unity-mcp-get-started.html` (watch for un-deprecation)

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; github.com/CoplayDev/unity-mcp/releases; github.com/IvanMurzak/Unity-MCP/releases; github.com/CoderGamester/mcp-unity/commits/main
- `path:SKILL.md "unity-mcp" OR "unity mcp"` on GitHub code search; `unity mcp server <year> site:github.com stars:>500`

Practice (how others use AI agents on this goal, and everything in between):

- `site:discussions.unity.com mcp claude code OR cursor <year>`; hn.algolia.com `unity mcp` sorted by date; vindler.solutions
- `"unity-mcp" "domain reload" issue <year>`

Testing (how the job is verified and what checkers exist):

- `claude mcp list unity connected`; `"mcp inspector" unity`; CoplayDev `run_tests` tool docs; `unity command get_console_logs` as verification
- `GameDevBench` and follow-ups for agent-on-Editor evaluation

Best sources (primary first): the three GitHub repos (README, releases, issues), docs.unity3d.com package manuals, unity.com/blog, the MCP registry API. Noisy: mcpservers.org, glama listings without dates, YouTube.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

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
