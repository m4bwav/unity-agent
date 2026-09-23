# Changelog: unity-agent-cli

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20260922-2 · 2026-09-22 · Refresh: the verification loop moves to `unity recompile` and `console`; new install line, exit codes, sandbox rule, Unity's plugin; L-006 and L-007 folded in
- because: R-20260922-1 to R-20260922-5, L-006, L-007 (the fold C-20260916-1 deferred to this refresh)
- files: SKILL.md (Step 1 install block; Step 2 route table and JSON note; Step 3 live Editor: command count, eval, verification loop, Play mode; tests line; MCP mode; skills line; Maintenance), evals/evals.json (action-2, action-3 added, not yet run), RESEARCH.md (header; Current understanding; Open questions; Search plan; R-20260922-1..5)
- `get_console_logs` no longer exists from Pipeline 0.7, so the loop now refreshes the AssetDatabase, runs `unity recompile` (beta.11) or `recompile` plus `console --level error`, and gives the Play-mode settle-and-retry rule. The install line is Unity's new canonical one; the unverified 5 s eval timeout is gone.

### C-20260922-1 · 2026-09-22 · Privacy scrub before the repository went public
- because: user request (publish the suite as a public repository); three privacy readers (paths and machines, people and working life, private projects)
- files: RESEARCH.md (Current understanding; R-20260906-4, R-20260906-5), LEARNINGS.md (L-002, L-004, L-006, L-007), evals/evals.json (trigger prompt), TESTS.md (T-20260906-1 env), evergreen.json (tests env), scripts/unity_probe.ps1 (example path)
- The private game project, the development machine's name and a personal account were generalised ("a Unity 6 game project", "the development machine", `dev-machine`); every R-, L-, C- and T- id kept.

### C-20260916-1 · 2026-09-16 · Two more live-Editor lessons: editor_play timing, AssetDatabase.Refresh
- because: L-006, L-007
- files: LEARNINGS.md (L-006, L-007)
- Learnings only; SKILL.md unchanged (the Screens line from C-20260915-1 already points at the capture command). Fold both into SKILL.md's verification loop at the next refresh.

### C-20260915-1 · 2026-09-15 · Screens line corrected: UI Toolkit needs `--source screen`, plus the runInBackground freeze
- because: L-004, L-005
- files: SKILL.md §Step 3 (verification loop, Screens), LEARNINGS.md (L-004, L-005)
- The verification loop no longer recommends `screenshot --view game` for UI work: it renders the camera only. It now names `capture_game_view --source screen` in Play Mode, the tilde-folder `save_path`, and the `Application.runInBackground = true` eval that keeps the player loop alive while the agent's terminal has focus. Both verified live on 6000.6.0f1 with pipeline 0.6.0-exp.1.

### C-20260906-3 · 2026-09-06 · Route table: manifest resolution needs a real user click; Pipeline 0.6 facts
- because: R-20260906-5, L-003
- files: SKILL.md §Step 2 (route table), RESEARCH.md §Current understanding / Open questions
- The "Editor open but no Pipeline package" row now says to have the user stop Play mode and click the Editor, and to wait for the descriptor before live commands. Verified 0.6.0-exp.1 with 149 commands on port 7800.

### C-20260906-2 · 2026-09-06 · action-1 evidence tightened after the baseline reached the CLI without the skill
- because: T-20260906-1
- files: evals/evals.json (action-1 evidence and baseline)
- With the CLI installed, a skill-less session can find the binary and run `unity status`; the case now requires the probe script or `unity pipeline list`, which the baseline never ran.

### C-20260906-1 · 2026-09-06 · Created as an evergreen unit (pointer mode) with the probe script
- because: user request; R-20260906-1, R-20260906-2, R-20260906-3, R-20260906-4; L-001, L-002
- files: SKILL.md (all sections), scripts/unity_probe.ps1, RESEARCH.md, LEARNINGS.md, TESTS.md, evals/evals.json, evergreen.json
- Initial version written from the July 2026 Unity CLI launch, the Pipeline 0.4 docs, Unity's own skill, and a local install of 1.0.0-beta.8. Tier `fast`, interval 14d. Route table (live vs batchmode vs Safe Mode), command reference, MCP mode, evidence rule. The probe script reports CLI, editors, running Editors, Pipeline state, lockfile and .NET SDKs in one JSON.
