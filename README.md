# unity-agent

![A small friendly robot at a workbench assembling glowing 3D cubes, spheres and tiny game characters on a miniature stage, workshop full of monitors](https://raw.githubusercontent.com/m4bwav/unity-agent/master/.github/images/banner.jpg)

Five self-maintaining ("evergreen") skills that teach an AI coding agent to drive Unity: from the
command line, headlessly, or over MCP. Written 2026-09-06 for Claude Code, GitHub Copilot, Cursor
and Codex, from a four-track research pass (subject, tooling, practice, testing) whose findings and
sources are recorded per skill in `RESEARCH.md`, and refreshed on a schedule since.

The headline that shaped the whole suite: Unity shipped an **official `unity` CLI** in July 2026
(beta, free) with an experimental `com.unity.pipeline` package that drives a *running* Editor over
local HTTP, plus a built-in `unity mcp` mode. Unity's own docs now mark the older in-Editor
Assistant MCP deprecated in its favour. So the suite leads with Unity's first-party route and
treats the popular community MCP servers as fallbacks.

In September 2026 Unity also published an official Claude Code plugin
([Unity-Technologies/unity-agent-plugin](https://github.com/Unity-Technologies/unity-agent-plugin))
whose `unity-cli` skill is the full command reference. This suite is the layer around it: which
route to take (live Editor, batchmode, MCP or code only), what evidence proves an action happened,
which MCP bridge fits which client, how to keep a Unity repo safe for agents, and how to manage
packages without the Editor UI. Each skill says when to point at Unity's own skills instead.

## The skills

| Skill | Job | Tier |
|---|---|---|
| [`unity-agent-cli`](skills/unity-agent-cli/SKILL.md) | Official Unity CLI and Pipeline package: editors, open/close, live Editor commands and `eval`, `unity recompile`, `unity test`, `unity build`, `unity mcp`. Ships `scripts/unity_probe.ps1`, one JSON with CLI, editors, running Editors, Pipeline state, lockfile and .NET SDKs | fast |
| [`unity-agent-headless`](skills/unity-agent-headless/SKILL.md) | Batchmode, Unity Test Framework CLI, an offline compile check that works while the Editor is open (dotnet build on Unity's generated csproj using the SDK bundled in every Unity install), Unity 6 log locations, exit-code traps, Hub CLI fallback. Ships `scripts/unity_headless.ps1` | moderate |
| [`unity-agent-mcp`](skills/unity-agent-mcp/SKILL.md) | Which MCP bridge to use (official `unity mcp`, CoplayDev, IvanMurzak, CoderGamester, docs servers), when MCP beats the CLI or code-only work, client configuration, domain-reload pitfalls, measured context footprint | fast |
| [`unity-agent-workflow`](skills/unity-agent-workflow/SKILL.md) | How an agent works safely and verifiably in a Unity repo: the verification ladder, YAML and .meta rules, Humble Object, test hygiene, skill packs worth pointing at, Unity's AI policy. Ships `references/AGENTS-snippet.md` | moderate |
| [`unity-agent-packages`](skills/unity-agent-packages/SKILL.md) | UPM from scripts and the command line: manifest edits, the Client API poll pattern (no `-quit`), Pipeline package commands, OpenUPM, AI-package version traps. Ships `references/PackageInstaller.cs` | moderate |

Each skill folder holds `SKILL.md` (the working document) plus its evergreen companions:
`RESEARCH.md` (dated findings with sources and a four-track search plan), `CHANGELOG.md` (every
change with the reason), `LEARNINGS.md` (procedural lessons with trigger and hypothesis),
`TESTS.md` + `evals/evals.json` (the cases that prove the skill triggers and acts, with baselines
run without the skill), `MAINTENANCE.md` and `evergreen.json` (tier, interval, due date, history).

Pointer mode: `evergreen.json` sets `"protocol": "plugin"`, so each skill follows whichever
evergreen plugin is installed ([evergreen-protocol](https://github.com/m4bwav/evergreen-protocol))
rather than carrying its own copy of the protocol. The skills work without that plugin;
`MAINTENANCE.md` carries the condensed rules for that case.

## Install

The skills install nothing on their own: the Unity CLI, the Pipeline package, Unity's own skills,
any MCP registration and a .NET SDK are all left to you to approve.

As a Claude Code plugin:

    /plugin marketplace add m4bwav/unity-agent
    /plugin install unity-agent@unity-agent

As plain skills for any agent that reads Agent Skills (Claude Code, Copilot CLI, VS Code Copilot,
Cursor, Codex, Gemini CLI): clone the repository somewhere stable and link each folder under
`skills/` into the agent's skills directory. Claude Code reads `~/.claude/skills/`; Copilot CLI
and several others read `~/.agents/skills/`; VS Code Copilot reads `~/.copilot/skills/` and a
repository's `.github/skills/`. Links let one clone serve every agent, and `git pull` updates them.

    git clone https://github.com/m4bwav/unity-agent
    # Windows (junctions need no admin rights)
    foreach ($s in Get-ChildItem unity-agent\skills -Directory) { New-Item -ItemType Junction -Path "$HOME\.claude\skills\$($s.Name)" -Target $s.FullName }
    # macOS / Linux
    for s in unity-agent/skills/*/; do ln -s "$PWD/$s" ~/.claude/skills/; done

Optional: with the evergreen plugin installed, `python <plugin>/scripts/evergreen.py register
<skill dir>` for each skill, so audits and refreshes see them. Tagged releases on GitHub also
carry a zip of the five skills.

## Verified on a real machine (2026-09-06)

Not claims from a model: measurements from a real run on Windows 11 with Unity 6000.5.0f1. Each
skill's RESEARCH.md records what has moved since.

- Unity CLI 1.0.0-beta.8 installs user-level to `%LOCALAPPDATA%\Unity\bin`, no admin, SHA-256
  verified. It is not on the PATH of the shell that installs it.
- `com.unity.pipeline` resolved as **0.6.0-exp.1** (newer than the 0.4 docs). An open Editor picks
  up the manifest change only after the user stops Play mode and clicks into the Editor window;
  programmatic focus does nothing. Afterwards `unity status` reported the Editor ready on port 7800
  with **149 registered commands**.
- `unity mcp` exposes those 149 commands as MCP tools: **96 KB of JSON schema, roughly 24k tokens**
  if a client loads every schema. That measurement is why the suite says to register it per project
  and prefer the CLI when context is the constraint.
- The offline compile check runs `dotnet build` on Unity's generated `Assembly-CSharp.csproj` in
  about 3 seconds **with the Editor still open**, using the .NET SDK that ships inside every Unity
  install (`Editor\Data\DotNetSdk`, 8.0.318) when no system SDK exists.
- Unity Hub's headless CLI fails from agent shells until `ELECTRON_RUN_AS_NODE` is cleared, because
  Claude Code and VS Code set it and Electron then runs as plain Node.

## Testing

Every skill carries an eval suite: trigger prompts, decoys that must *not* fire it, action cases
proven by a tool call in the trace rather than by the reply's wording, and a baseline of the same
prompt run without the skill. Twelve cases were run through fresh subagents at creation (one run
per case rather than the suite's three) and all passed; `TESTS.md` in each skill records the runs.
Two baselines reached the same answer without the skill, more slowly, so those cases' evidence
rules were tightened rather than left redundant. One real defect surfaced that way: the compile
driver's log came back empty on a clean build, recorded as a learning and fixed.

CI (`.github/workflows/tests.yml`) runs `tests/check_skills.py` on Linux and Windows (frontmatter,
the 1,024-character description limit, companions, manifests, relative links, and public-safety
guards) and `tests/check_scripts.ps1` in PowerShell 7 and Windows PowerShell 5.1, which parses
both scripts and runs them on a runner with no Unity installed: each must still print one JSON
object.

## Privacy

unity-agent has no server and collects nothing. The skills are instructions for your agent, and
the two PowerShell scripts run on your machine and print one JSON object each. They make no
network calls of their own. `unity_probe.ps1` runs the local `unity` CLI (`--version`,
`editors --installed`, `pipeline list`), lists running Unity processes, and reads two files in
the project: `Temp/UnityLockfile` and the Pipeline descriptor in `Library/Pipeline`. That
descriptor holds the local token the Pipeline server uses to accept commands from the CLI. The
probe reads it only to report the server's process id, port and heartbeat; it never prints,
stores or uses the token. `unity_headless.ps1` reads Unity Hub's list of installed editors and
starts the Editor in batchmode on your project. Neither script reads any other credential or
environment variable beyond the standard folder locations (`LOCALAPPDATA`, `APPDATA`).

Network traffic comes from the tools the skills tell the agent to run, each only after you
approve it. The Unity CLI and the Editor talk to Unity's services for sign-in, licensing, editor
and package downloads, docs and the issue tracker, under Unity's terms. The Pipeline server that
Unity's MCP mode talks to listens on 127.0.0.1 only. Installing a community MCP server fetches it from GitHub, OpenUPM or
npm. The two `npx` commands the skills name, `skills@1.7.0` to add Unity's skill pack and
`@modelcontextprotocol/inspector@2.9.0` to list an MCP server's tools, download those exact
versions from npm. Nothing is kept by this plugin; the tools above keep their own caches and
settings.

## If you are an agent asked to analyze this suite

Worth your attention, roughly in order: `skills/*/SKILL.md` for how each skill decides and what
evidence it demands before reporting done; `skills/*/RESEARCH.md` for the dated sources behind
every time-sensitive claim and the four-track search plan that keeps them current;
`skills/*/evals/evals.json` and `TESTS.md` for how the skills are proven rather than asserted;
`skills/unity-agent-cli/scripts/unity_probe.ps1` and
`skills/unity-agent-headless/scripts/unity_headless.ps1` for the deterministic work, both of which
emit one JSON object so a caller never parses prose. The design rule running through all of it is
that a skill passes on evidence outside the transcript, never on its own claim that something was
done. Rules for working in the repository are in [AGENTS.md](AGENTS.md).

Known limits worth checking: the Unity CLI is beta and its command surface moves monthly; the
Pipeline package is experimental (`0.6.0-exp.1` when first tested, 0.7.0-exp.1 at the last
refresh) and pinned versions drift; community MCP server star counts and versions are snapshots
from the last refresh; and the eval suites were run once per case, not the three runs their own
rules ask for.

License: MIT.
