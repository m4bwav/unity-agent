# Research: unity-agent-workflow

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: how AI coding agents work safely in Unity projects: verification ladder, YAML and .meta rules, Humble Object testing, agent skill packs for Unity, Unity's AI policies and agent roadmap. Tier `moderate`. Last refresh 2026-09-06; next due 2026-10-06.

## Current understanding

- Practitioner consensus in 2026 (Unity Discussions threads including Unity-MCP maintainers): code-only agent work is the most reliable; generate editor scripts rather than emit `.unity`/`.prefab` YAML (token-hungry, unreliable); UI layout stays fragile; asset-index files and naming conventions help agents.
- Verification: engine-free NUnit projects that link `Assets/**/*.cs` (with a `UnityEngine` stub, or against `UnityEngine.CoreModule.dll`) are a documented mainstream pattern (gamedev.center 2026-03); `dotnet build` on the Unity-generated csproj is a whole-assembly compile check; Unity Test Framework via `unity test` or `-runTests`; live checks via Pipeline `recompile`, `get_console_logs`, `screenshot`, `eval`. Research prototypes (arXiv 2603.07101, 2608.25518, GameDevBench 2602.11103) verify generated Unity code by compile plus scripted replay and state assertions; none is a drop-in harness.
- Skill packs: Unity-Technologies/skills (official, MIT, ~730 stars, 13-14 skills, `npx skills add`), nowsprinting/unity-coding-skills (test-first; Rider MCP dependency; successor to the archived claude-code-settings-for-unity), Nice-Wolf-Studio/unity-claude-skills (35 skills, WHEN/WRONG/RIGHT/GOTCHA), gamedev-skills/awesome-gamedev-agent-skills (67 skills, router), Besty0728/Unity-Skills (in-Editor installer). No Unity entry in github/awesome-copilot; cursor.directory Unity rules are generic C# style.
- Unity roadmap: Unity CLI + Pipeline (July 2026) is the official agent path; `unity mcp` replaces the Assistant MCP; Unity 6.6 defaults Fast Enter Play Mode; Unity 7 preview Dec 2026, release Q1 2027, positioned around agent collaboration; CoreCLR migration (6.7+) may affect bridges.
- Policy: Unity ToS updated 2026-06-30 (automated tools act under the account holder's responsibility); Asset Store allows AI-generated content with disclosure and bans training on Store assets (2025-08-06); Unity AI Guiding Principles page exists. Nothing restricts a hobby project.
- This skill's repo-independent rules were written against the AGENTS.md of a Unity 6 game project (Humble Object, importer-first, .meta handling, save-data risk), which already encodes them.

## Open questions

- Which skill pack, if any, gains real install counts on skills.sh (only Unity-Technologies shows numbers so far).
- Does Unity publish agent-facing guidance (an `llms.txt`, an "AI in Unity" manual page) beyond the CLI skill?
- Does Fast Enter Play Mode by default (6.6) change the domain-reload rule for agents?

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `unity.com/blog agents OR "ai agents" editor <month year>`; `unite <year> keynote recap ai`
- `unity.com/legal` and `support.unity.com` "AI" policy pages (diff against the last refresh)

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `path:SKILL.md unity` on GitHub code search sorted by recently updated; `npx skills find unity`; skills.sh unity; github.com/Unity-Technologies/skills commits; nowsprinting/unity-coding-skills releases
- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; `awesome-copilot unity`; cursor.directory unity

Practice (how others use AI agents on this goal, and everything in between):

- `site:discussions.unity.com "claude code" OR cursor OR codex workflow <year>`; hn.algolia.com `unity "claude code"` by date; r/Unity3D `agent` with a date filter
- `"unity" agent "yaml" prefab scene generate editor script <year>`

Testing (how the job is verified and what checkers exist):

- `site:arxiv.org unity agent verification replay <year>`; `GameDevBench`; `unity humble object dotnet test <year>`
- `unity test framework play mode screenshot diff agent <year>`

Best sources (primary first): unity.com/blog, discussions.unity.com (dated threads), the skill repos on GitHub, arXiv cs.SE. Noisy: Medium (403), YouTube, generic "AI game dev" listicles.

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20260906-4 · 2026-09-06 · Practice: agent test hygiene from a no-experience Unity project (r/ClaudeAI thread)
- Summary: A widely upvoted r/ClaudeAI post (2026-09-06, "Day 5 of making a cozy game", Unity via Claude Desktop, no dev background) and its comments. The OP's process matches this skill's ladder: small scoped updates, git rollback for every change, a ~150-item check pass after each change with screenshots as evidence, and the human re-checking the screenshots. Two cautions from an experienced commenter were the actionable part: an agent told "add tests" produces tautological tests that catch nothing, and when tests break the agent tends to call them "pre-existing" so red tests accumulate and get ignored. Added as a Step 2 rule. The OP's model mix, costs, and 3D pipeline (Gemini images, Meshy, Blender scripts) are self-reported and not relevant to a verification skill; not recorded.
- Track: practice
- Sources: an r/ClaudeAI post and a reply from an experienced commenter, 2026-09-06 (thread text supplied by the user; not fetched)
- Magnitude: 0.2
- Applied: C-20260906-2

### R-20260906-3 · 2026-09-06 · Verification research and headless-test practice
- Summary: gamedev.center pattern for linking Unity sources into a .NET NUnit project; Unity Discussions on Humble Object; arXiv replay/verification papers and GameDevBench. Applied as the ladder and the "not a drop-in harness" note.
- Track: testing
- Sources: https://gamedev.center/run-unity-tests-faster-dotnet/, https://discussions.unity.com/t/humble-object-pattern-unit-testing-compatibility-vs-integration-test-compatibility/606262, https://arxiv.org/abs/2603.07101, https://arxiv.org/html/2608.25518, https://arxiv.org/html/2602.11103v2
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-2 · 2026-09-06 · Skill packs for Unity agents, ranked
- Summary: Unity-Technologies/skills, nowsprinting/unity-coding-skills (and the archived predecessor), Nice-Wolf-Studio, gamedev-skills, Besty0728, The1Studio. No awesome-copilot Unity entry. Applied as the pointers section.
- Track: tooling
- Sources: https://github.com/Unity-Technologies/skills, https://github.com/nowsprinting/unity-coding-skills, https://github.com/nowsprinting/claude-code-settings-for-unity, https://github.com/Nice-Wolf-Studio/unity-claude-skills, https://github.com/gamedev-skills/awesome-gamedev-agent-skills, https://github.com/Besty0728/Unity-Skills
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Practitioner consensus, Unity roadmap, and AI policy
- Summary: Unity Discussions threads on CLI/MCP/agent workflows (YAML emission unreliable; editor scripts win); Unite Seoul 2026 recap (6.6 Fast Enter Play Mode default, Unity 7 timeline); ToS 2026-06-30 and Asset Store AI policy.
- Track: practice
- Sources: https://discussions.unity.com/t/cli-mcp-ai-ide-chatgpt-codex-cursor-antigravity-claude-code-windsurf-next-steps-for-unity-workflow-automation/1705679, https://discussions.unity.com/t/i-made-a-reference-doc-to-help-ai-agents-claude-cursor-use-the-unity-cli-mcp/1733846, https://unity.com/blog/unite-seoul-keynote-2026-recap, https://unity.com/legal, https://support.unity.com/hc/en-us/articles/16456407029524
- Magnitude: n/a (initial)
- Applied: C-20260906-1
