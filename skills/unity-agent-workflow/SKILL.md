---
name: unity-agent-workflow
description: "How an AI coding agent works inside a Unity project so its changes are verifiable: the verification ladder (engine-free tests, offline compile check, Unity Test Framework, live Editor checks), the rules that keep Unity repos safe for agents (never hand-write scene/prefab/asset YAML, keep .meta files with their assets, Humble Object logic, importers over hand-edited assets, domain reload), repo setup for agents (AGENTS.md snippet, skill packs, .gitignore, csproj generation) and Unity's stance on AI-made content. Use whenever the user asks how Claude, Copilot, Cursor or Codex should work with Unity, wants a Unity repo set up for AI agents, asks for Unity coding conventions for agents or the latest thinking on AI with Unity, asks why an agent edit broke a scene or .meta, or says 'refresh unity-agent-workflow' / 'is unity-agent-workflow stale'. The CLI is unity-agent-cli; batchmode and compile checks are unity-agent-headless; MCP servers are unity-agent-mcp; packages are unity-agent-packages."
---

# Unity agent workflow (how to work in a Unity repo and prove it)

Outcome: the agent's Unity change is made through a route that leaves evidence, verified at
the lowest rung that can catch the mistake, and the repo carries the rules so the next agent
does the same.

## Step 0: freshness (every use, one read)

Read `evergreen.json` next to this file. If `verify_at_use` is true, re-check the listed `volatile_claims` before relying on them. If `contradiction` is set or today is on or after `next_due`, tell the user in one line, do the task with the current content, then run the refresh (`evergreen-refresh`) in the same session. If `tests.failing` is non-empty, say so in one line and run `evergreen-tune` after the task. Never block the task on a refresh unless the task depends on the stale claim.

## Step 1: read the repo's own rules first

Look for `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, a `CODEMAP.md`, and any `.claude/skills` or `.agents/skills` folders. Repo rules win over this skill. If none exist, offer the snippet in `references/AGENTS-snippet.md` (do not add it unasked).

## Step 2: the verification ladder (lowest rung that can catch the mistake)

| Rung | Catches | Cost | How |
|---|---|---|---|
| 1. Engine-free unit tests | logic, math, state, determinism | seconds, Editor may be open | a `dotnet test` project that links `Assets/Scripts` sources with a small `UnityEngine` stub (Humble Object: rules in plain C#, MonoBehaviours as thin shells) |
| 2. Offline compile check | every C# error in the player and editor assemblies | ~3 s, Editor may be open | `dotnet build Assembly-CSharp.csproj` with a system or Unity-bundled SDK (unity-agent-headless) |
| 3. Unity Test Framework | Editor APIs, serialization, scene loading, play-mode behaviour | minutes, Editor closed (or live via the Pipeline package) | `unity test --mode EditMode|PlayMode` (unity-agent-cli) or batchmode `-runTests` |
| 4. Live Editor checks | what it looks like and logs at runtime | seconds per call, Editor open with Pipeline | `recompile` + `get_console_logs --severity error`, `editor_play`, `screenshot`, `eval` for state |
| 5. Human in the Editor | feel, art, UX | the user's time | describe the exact repro path |

Rule: a red rung is never "pre-existing". When a test or compile check fails after a change, fix it or report it as failing with the output; do not label it pre-existing and move on, because unexamined red tests pile up and the ladder stops meaning anything. Tests that only restate the code (tautological asserts) do not count as a rung; a test must fail when the behaviour breaks.

Rule: `dotnet test` green is not a compile check for engine-side files; before claiming a rename or removal is safe, grep all of `Assets` for every affected symbol and run rung 2.

## Step 3: rules that keep a Unity repo safe for agents

- Never hand-write or regex-edit `.unity`, `.prefab`, `.asset`, `.controller`, `.mat` YAML, and never touch them at all while an Editor has the project open. Generate or change them through an editor script, an importer that reads a text source, a `[MenuItem]` the user can run, `-executeMethod`, or the Pipeline commands. Practitioners and the Unity-MCP maintainers agree direct YAML emission is unreliable and token-hungry.
- Every file under `Assets/` needs a `.meta`; commit them together and `git mv` them together. A file created outside the Editor gets its `.meta` on the next import (`AssetDatabase.Refresh`) or from a repo helper; never regenerate an existing `.meta` (the GUID is the asset's identity).
- Keep gameplay rules in plain C# classes with `System.Math`, injected data and `event Action<...>` outputs, so rung 1 reaches them. `UnityEngine` calls live in thin MonoBehaviours.
- Content (cards, items, levels) comes from text sources through an importer; hand-edited generated assets are overwritten on the next import. Change the source and the importer together.
- Domain reload: any recompile, Play-mode entry, or package change restarts bridges and clears static state. Batch edits, then verify once.
- Editor lock: batchmode and a second Editor cannot open a project the Editor holds; the Pipeline route is for the open Editor, batchmode for the closed one.
- Unity 6 logs live per project in `<project>/Logs/`; read `Editor.log` there, not the global one.
- Save systems and serialized fields: adding a field is safe; renaming or removing one silently drops data. Flag any change to a serialized or save-reachable type.
- Don't add asmdefs, DI containers, Addressables, or new packages without asking; they change compile units and import behaviour for everyone.

## Step 4: tooling worth pointing at (verify state at refresh)

- Unity-Technologies/skills (MIT, official): `npx skills add Unity-Technologies/skills` gives `unity-cli`, `unity-package-management`, `ui` router with `ui-uitk` (UI Toolkit), `ui-ugui`, `ui-imgui`, `validate-urp-render-graph-renderer-feature`, `shader-graph-create-custom-node`, multiplayer, IAP, LevelPlay, `new-unity-project`. `unity skill install <client>` does the same for the CLI skill.
- nowsprinting/unity-coding-skills (Unlicense): test-first Unity skills (`plan-feature`, `fix-bug`, `run-tests`, `unity-yaml-editing-guide`, `test-designing-guide`); the test and scene skills depend on Rider's MCP.
- Nice-Wolf-Studio/unity-claude-skills: 35 topic skills in a WHEN/WRONG/RIGHT/GOTCHA format; gamedev-skills/awesome-gamedev-agent-skills: router over 60+ game-dev skills.
- Unity's own agentic path: Unity CLI + Pipeline (unity-agent-cli), `unity mcp` (unity-agent-mcp). Unity 6.6 makes Fast Enter Play Mode (no domain reload on play) the default; Unity 7 (preview late 2026) is positioned around agent collaboration.
- Benchmarks and verification research: GameDevBench (arXiv 2602.11103), replay-based verification of generated Unity code (arXiv 2603.07101). Use them for ideas, not as harnesses.

## Step 5: Unity's stance on AI-made work (for a hobby or commercial project)

Unity's Terms (updated 2026-06-30) let automated tools act on your account under your responsibility. The Asset Store allows AI-generated content with disclosure in the AI description field and bans training on Store assets. Unity AI features (Assistant, Generators) need a Unity Cloud project and their own terms; nothing restricts a project from using agent-written code with a normal Unity licence. Say this in one line when the user asks about permission; don't lecture.

## Output

For "how should the agent work here": the ladder rung(s) you will use for the task, the route for any asset change, and the evidence you will show. For "set up the repo": the files you propose to add (snippet, skills, csproj generation) and what each prevents.

## While working: capture learnings

If the user corrects you, the same error happens twice, a workaround is found, or an environment fact is discovered, write it to `LEARNINGS.md` now (format in MAINTENANCE.md; check existing entries first: add, update, retire, or nothing). If a learning proves a claim above wrong, fix it here, log it in `CHANGELOG.md`, and set `contradiction` in `evergreen.json`.

## Maintenance

This skill is evergreen (topic: how AI agents work safely and verifiably in Unity projects; tier `moderate`, currently every 30d, next due 2026-10-06). Files: `evergreen.json` (state), [RESEARCH.md](RESEARCH.md) (findings and search plan), [CHANGELOG.md](CHANGELOG.md) (every change, with reasons), [LEARNINGS.md](LEARNINGS.md) (lessons), [TESTS.md](TESTS.md) and `evals/evals.json` (the cases that prove it and the runs). Protocol: MAINTENANCE.md (pointer to the installed evergreen plugin). Refresh with `evergreen-refresh`; test with `evergreen-test`; fix a failure with `evergreen-tune`; audit with `evergreen-audit`. Sibling skills in this suite: unity-agent-cli, unity-agent-headless, unity-agent-mcp, unity-agent-workflow, unity-agent-packages.
