---
name: unity-agent-mcp
description: "Choose, install, configure, and troubleshoot an MCP server that lets an AI agent (Claude Code, Claude Desktop, Copilot, Cursor, Codex) see and edit a running Unity Editor: Unity's official unity mcp mode (from the Unity CLI and com.unity.pipeline), CoplayDev MCP for Unity, IvanMurzak Unity-MCP, CoderGamester mcp-unity, docs servers, and when to use MCP versus the CLI versus code-only work. Use whenever the user asks 'is there an MCP server for Unity', 'connect Claude to Unity', 'let the agent see the scene', 'add unity-mcp', 'which Unity MCP should I use', 'configure MCP for the editor', reports the Unity MCP bridge dropping after a domain reload or play mode, or says 'refresh unity-agent-mcp' / 'is unity-agent-mcp stale'. Running CLI commands against the Editor once a route is chosen is unity-agent-cli; batchmode and compile checks are unity-agent-headless."
---

# Unity MCP (agent to Editor bridges)

Outcome: the user gets a clear recommendation and, if they say yes, a working MCP entry whose
tools are visible to the client (`claude mcp list` shows it connected, or the client lists its
tools), plus the pitfalls that apply to their Unity version.

## Step 0: freshness (every use, one read)

Read `evergreen.json` next to this file. If `verify_at_use` is true, re-check the listed `volatile_claims` before relying on them. If `contradiction` is set or today is on or after `next_due`, tell the user in one line, do the task with the current content, then run the refresh (`evergreen-refresh`) in the same session. If `tests.failing` is non-empty, say so in one line and run `evergreen-tune` after the task. Never block the task on a refresh unless the task depends on the stale claim.

## Step 1: decide whether MCP is the right tool

Ask what the agent needs to do, then pick the lowest rung that covers it:

1. Code only (no bridge): C# in plain classes, headless tests, importers and editor scripts that the user runs. Most gameplay and tooling work. Nothing to install.
2. CLI (unity-agent-cli): the same Pipeline commands as the official MCP, but each call is a shell command with JSON output that the agent can log and replay. Best default for Claude Code and Copilot CLI: no config, no idle server, works in scripts. Unity's official Claude Code plugin (`/plugin install unity@unity-agent-plugin`) installs this route's skills and registers no MCP server.
3. MCP: when the client cannot run shell commands well (Claude Desktop, Cursor chat), when the agent needs many small scene inspections per turn, or when the user wants tool-level permissions. Official `unity mcp` first; a community server only for something it does that the official one lacks. Footprint (measured 2026-09-06 on Pipeline 0.6): the official server exposes 149 tools, about 24k tokens of schema if the client loads them all; Claude Code defers MCP schemas so it pays only the name list, while Claude Desktop and Cursor pay in full. Register it per project (`claude mcp add --scope local`), never globally, and prefer the CLI when context is the constraint.

Say which rung you picked and why in one line.

## Step 2: the servers (state as of the last refresh; verify versions when it matters)

| Server | What it is | Install | Notes |
|---|---|---|---|
| Official: `unity mcp` (Unity CLI 1.0.0 beta + `com.unity.pipeline` 0.7 exp, Unity 6.0+) | stdio MCP over the Pipeline HTTP API: about 150 commands, 149 measured on 0.6 (scene, GameObject, components, prefabs, assets, tests, console, screenshots, play mode, build, `eval`) | `unity pipeline install` in the project (asks first: edits `Packages/manifest.json`, domain reload), then `unity mcp configure <client>` (16 clients, `claude-code` included; `--dry-run` previews the entry) or, in Claude Code, `claude mcp add --scope local unity -- unity mcp --project-path "<abs project>"` | Free, no subscription. Replaces the in-Editor "Unity MCP" of the AI Assistant package, which Unity marks deprecated. Experimental package: pin the version in the manifest; 0.7.0-exp.1 removed `get_console_logs` (use `console`) |
| CoplayDev/unity-mcp ("MCP for Unity", MIT, ~14k stars, Unity 2021.3 to 6.x, v10) | Python/uv server plus an Editor bridge; 47 tools in groups, only `core` enabled by default, so activate the `testing` group before `run_tests`; script validation, AI asset generation | OpenUPM `com.coplaydev.unity-mcp` or git URL `https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity#main`; needs Python 3.10+ and uv; the Editor window configures clients | Most-used community server; older Unity versions; HTTP bridge drops on domain reload and reconnects |
| IvanMurzak/Unity-MCP (Apache-2.0, ~4k stars, Unity 6, 0.91) | 70+ tools, stdio and streamable HTTP, `[AiTool]` turns any C# method into a tool, in-Player runtime use, batchmode support | `npm i -g unity-mcp-cli` or OpenUPM `com.ivanmurzak.unity.mcp` | Project path must not contain spaces (this rules it out for paths like `D:\My Unity Projects\...`) |
| CoderGamester/mcp-unity (MIT, ~2k stars, Unity 6+) | Node WebSocket server on port 8090 | git URL package plus `npm` | Third by adoption; batchmode only with `MCP_UNITY_ALLOW_BATCH_MODE=true`; 1.5.0 requires a per-project token (`Library/McpUnity/bridge-token`), so regenerate client configs after upgrading |
| Docs and known bugs | `unity docs <topic>` (CLI beta.11+) opens the docs matched to the project's Unity version; Unity's remote Issue Tracker MCP for known bugs; community `Codeturion/unity-api-mcp` for API signatures | `unity mcp configure <client> --server issue-tracker` (beta.11+); the community server from the MCP registry | `saqoosha/unity-docs-mcp` is unmaintained since 2025-06. docs.unity.com publishes an `llms.txt`; the docs.unity3d.com manual has none. The CLI also ships an offline `unity changelog` |

The official MCP registry (registry.modelcontextprotocol.io) has no `unity mcp` entry as of the last refresh; its Unity entries are small community bridges. Rank by stars and last commit, not by directory listings.

## Step 3: install and verify (only after the user says yes)

1. Confirm the Editor is open on the right project (`unity pipeline list` or the probe in unity-agent-cli) and that no second Editor could make the target ambiguous.
2. Install the package route chosen above. For the official server: `unity pipeline install --project-path "<abs>"`, wait for the domain reload, then `unity status` must show the instance reachable.
3. Register the server with the client. Claude Code (local scope, this project only): `claude mcp add --scope local unity -- unity mcp --project-path "<abs>"`, or `unity mcp configure claude-code` (preview it with `--dry-run`). Other clients: `unity mcp configure <client>` writes the file it lists in `unity mcp configure --list`.
4. Verify: `claude mcp list` reports the server connected (or the client's tools panel lists `unity` tools), then call one read-only tool such as the editor status or hierarchy. For a client with no status command, `npx @modelcontextprotocol/inspector --cli unity mcp --project-path "<abs>" --method tools/list` lists the tools as JSON. That call's result is the evidence; the config file alone is not.

## Step 4: pitfalls to state up front

- Domain reload (recompile, package changes, and entering Play mode unless Enter Play Mode Options skip it, the default for new Unity 6.6 projects) restarts every bridge. The official Pipeline token survives reloads within a session but rotates on Editor restart; community HTTP bridges drop and reconnect after a delay. Expect a failed call right after a reload; retry once, then re-read state.
- Compile errors put the Editor in Safe Mode; the Pipeline server does not load and MCP calls fail. Fix the C# first (unity-agent-headless compile check).
- An unfocused or minimized Editor may stop ticking; official: `set_autotick`; community: click the Editor window.
- Modal dialogs block everything; start the Editor with `-automated` for unattended sessions.
- Unity 6000.5.x plus `com.unity.ai.assistant` 2.13-pre livelocks the AssetDatabase at startup (Unity bug UUM-132096, reported June 2026). Do not add the Assistant package on 6.5 just to get MCP; the CLI route needs no AI package.
- Agents must not hand-edit `.unity`, `.prefab`, or `.asset` YAML while an Editor holds the project; go through the bridge or write an editor script (unity-agent-workflow).
- Two Editors open: pass `--project-path` everywhere; the CLI otherwise errors with `AMBIGUOUS_EDITOR`.
- A tool's success is not the Editor's state: re-read the editor status after Play or a test run (a community bridge has reported Play as started while Unity cancelled it), and trust `claude mcp list` over an Editor window that says "Not Configured". When the Editor's main thread is blocked, the official server's captures fall back to a screenshot of the whole desktop.

## Output

Recommendation (one rung, one server), the install and register commands the user would approve, and the verification evidence once it ran.

## While working: capture learnings

If the user corrects you, the same error happens twice, a workaround is found, or an environment fact is discovered, write it to `LEARNINGS.md` now (format in MAINTENANCE.md; check existing entries first: add, update, retire, or nothing). If a learning proves a claim above wrong, fix it here, log it in `CHANGELOG.md`, and set `contradiction` in `evergreen.json`.

## Maintenance

This skill is evergreen (topic: MCP servers bridging agents to the Unity Editor; tier `fast`; the schedule is in `evergreen.json`). Files: `evergreen.json` (state), [RESEARCH.md](RESEARCH.md) (findings and search plan), [CHANGELOG.md](CHANGELOG.md) (every change, with reasons), [LEARNINGS.md](LEARNINGS.md) (lessons), [TESTS.md](TESTS.md) and `evals/evals.json` (the cases that prove it and the runs). Protocol: MAINTENANCE.md (pointer to the installed evergreen plugin). Refresh with `evergreen-refresh`; test with `evergreen-test`; fix a failure with `evergreen-tune`; audit with `evergreen-audit`. Sibling skills in this suite: unity-agent-cli, unity-agent-headless, unity-agent-mcp, unity-agent-workflow, unity-agent-packages.
