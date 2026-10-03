# Changelog: unity-agent-mcp

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

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
