# Changelog: unity-agent-mcp

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20261030-1 · 2026-10-30 · CLI beta.15: unique tool names, job tools, `unity list` removed
- because: R-20261030-1
- files: SKILL.md (Step 1 ladder, MCP rung; Step 4 pitfalls, two Editors)

### C-20261023-1 · 2026-10-23 · Refresh: Pipeline 0.9 shipped, CLI beta.14 tool filters and pinning, 0.9 upgrade pitfall, IvanMurzak 1.5
- because: R-20261023-1, R-20261023-2, R-20261023-3, R-20261023-4
- files: SKILL.md (Step 1 rungs 2 and 3; Step 2 official and IvanMurzak rows; Step 3.3; Step 4 new upgrade bullet and two Editors bullet), RESEARCH.md (header; Current understanding; Open questions; Search plan, Subject and Tooling; R-20261023-1..4), evals/evals.json (outcome-2)
- The official row said 0.9 was announced with no date; it shipped 2026-10-20 with grouped commands and old names gone, and needs CLI beta.14. Rung 3 and Step 3 now offer `unity mcp --tools` to cut the schema footprint. Step 4 names the 0.9 rollout bugs. The IvanMurzak row moves to 1.5.0 with the real tool count.

### C-20261017-1 · 2026-10-17 · Refresh: IvanMurzak 1.x RQL upgrade warning, Pipeline-on-Unity-7 fix source, Unity's unity-pipeline skill
- because: R-20261017-1, R-20261017-2, R-20261017-3
- files: SKILL.md (Step 1 rung 2; Step 2 official row and IvanMurzak row; Step 4 Unity 7 bullet), RESEARCH.md (header; Current understanding: official route and community ranking; Open questions; Search plan, Subject and Tooling and Testing; R-20261017-1..3)
- The IvanMurzak row named 0.93; 1.0.0 replaced its data tools with RQL, so tool names in allow-lists break on upgrade, and 1.1.0 moved the add-ons into separate packages. The official row now says the Unity 7 build block is fixed by a Unity 7 alpha, not Pipeline. Rung 2 points at Unity's new `unity-pipeline` skill. No trigger or decision changed, so the eval suite was not re-run (AGENTS.md rule).

### C-20261014-1 · 2026-10-14 · Quiet refresh: versions in Current understanding, forum lines in the Search plan
- because: R-20261014-1
- files: RESEARCH.md (header; Current understanding: official route and community ranking; Open questions: Pipeline 0.9; Search plan, Subject: package feeds and an official forum and announcements line; R-20261014-1)
- Current understanding still named CoplayDev v10.2.0 and IvanMurzak 0.93.2; the Search plan had no discussions.unity.com line with URLs. SKILL.md needed no change.

### C-20261011-1 · 2026-10-11 · Pipeline 0.9 rename warning, CoplayDev fix released, dialog status, UNITY_PROJECT_PATH, Unity 7 note
- because: R-20261011-1, R-20261011-2
- files: SKILL.md (Step 2: official row, CoplayDev row, registry note; Step 4: Unity 7, dialogs, two Editors), RESEARCH.md (two findings, Open questions)
- The official row warns that 0.9 renames tools; CoplayDev's 6000.6 fix is in v10.3.0; `STATUS_BLOCKED_BY_DIALOG` and `UNITY_PROJECT_PATH` come from CLI beta.13.

### C-20261003-2 · 2026-10-03 · Inspector command pinned to 2.9.0
- because: user request (Claude plugin directory submission)
- files: SKILL.md (Install and verify, step 4)
- The Claude plugin directory wants every package a launcher runs pinned. `@modelcontextprotocol/inspector@2.9.0` is the current release (`npm view`, 2026-10-03); its `--cli <server> --method tools/list` returned a stub server's tool list as JSON.

### C-20261003-1 · 2026-10-03 · Refresh: Pipeline 0.8 in the official row, beta.12 duplicate check, CoplayDev on Unity 6000.6, scene-reload dialog
- because: R-20261003-1, R-20261003-2
- files: SKILL.md (Step 2 official, CoplayDev, IvanMurzak and docs rows; Step 3.3; Step 4 modal dialogs bullet), RESEARCH.md (header; Current understanding; Open questions; Search plan, Tooling; R-20261003-1 to 3)
- The official row named Pipeline 0.7; `unity mcp configure claude-code` now skips when a plugin already runs the server; CoplayDev v10.2.0 breaks on 6000.6 until a release carries #1399; the Save/Reload-scene prompt is named as the dialog that stalls agents.

### C-20260922-2 · 2026-09-22 · Refresh: Pipeline 0.7 and CLI beta.11 in the official row, Claude Code at local scope, tool groups, docs row, Inspector evidence
- because: R-20260922-1 to R-20260922-6
- files: SKILL.md (Step 1 rung 2; Step 2 official, CoplayDev, IvanMurzak, CoderGamester and docs rows, registry note; Step 3.3 and 3.4; Step 4 reload bullet and a new bullet on tool success versus state; Maintenance), evals/evals.json (outcome-1 accepts either register command; action-2 added, not yet run), RESEARCH.md (header; Current understanding; Open questions; R-20260922-1..6)
- Step 3 said "user scope" while Step 1 said local scope; both now say local. The docs row no longer claims there is no `llms.txt` and no longer recommends an unmaintained server.

### C-20260922-1 · 2026-09-22 · Privacy scrub before the repository went public
- because: user request (publish the suite as a public repository); three privacy readers
- files: SKILL.md (IvanMurzak row example path), RESEARCH.md (Current understanding; R-20260906-4), LEARNINGS.md (L-001), evals/evals.json (action prompt), TESTS.md (T-20260906-1 env), evergreen.json (tests env)
- A real local path, the private game project and the development machine's name were generalised; every id kept.

### C-20260906-2 · 2026-09-06 · Step 1 states the measured footprint and the local-scope rule
- because: R-20260906-4
- files: SKILL.md §Step 1
- 149 tools / ~24k tokens for the official server; register per project at local scope; CLI when context matters.

### C-20260906-1 · 2026-09-06 · Created as an evergreen unit (pointer mode)
- because: user request; R-20260906-1, R-20260906-2, R-20260906-3
- files: SKILL.md (all sections), RESEARCH.md, LEARNINGS.md, TESTS.md, evals/evals.json, evergreen.json
- Initial version. Tier `fast`, interval 14d. Three-rung decision (code only, CLI, MCP), server table led by the official `unity mcp`, install-and-verify steps gated on the user's yes, pitfalls from issue trackers and field reports.
