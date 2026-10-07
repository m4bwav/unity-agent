# Changelog: unity-agent-cli

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20261006-1 · 2026-10-06 · Asset imports through the Pipeline: set settings with a dry run, prove the import by loading it; `unity build --timeout`
- because: R-20261006-1, R-20261006-2, L-010, L-011 (lessons from a settlement game's asset workflows, checked against the installed CLI and a live Editor)
- files: SKILL.md (Step 3, Live Editor: new "Asset imports" bullet; Tests and builds: build line), LEARNINGS.md (L-010, L-011), RESEARCH.md (Open questions: eval timeout resolved; R-20261006-1, R-20261006-2), evergreen.json (counts)
- One new bullet names `set_import_settings`, `get_import_settings` and `import_asset`, the `unknown` list a green envelope can hide, and the load-it-in-eval proof with Play mode stopped; the build line gains `--timeout` and the heartbeat. No trigger or route changed, so the evals were not re-run.

### C-20261004-1 · 2026-10-04 · eval quoting from PowerShell breaks; batch items in one eval
- because: L-009 (seven PowerShell evals with `\"` all failed to compile; one Bash single-quoted eval with a loop wired all seven); L-008 update (a piped `unity open` returned once in a Claude Code PowerShell call)
- files: SKILL.md (Step 3, Live Editor: eval bullet), LEARNINGS.md (L-008 update, L-009)
- One clause on the eval bullet; the Start-Process rule for `unity open` is unchanged.

### C-20261003-2 · 2026-10-03 · Install step: winget first, Unity's script downloaded and read before it runs
- because: user request (Claude plugin directory submission)
- files: SKILL.md (Step 1: CLI missing)
- The Claude plugin directory flags piping a downloaded script straight into the shell. `winget install Unity.CLI` (checked 2026-10-03 with `winget show`: Unity CLI 1.0.0-beta.12) leads; Unity's install script stays as a second route, saved and read before it runs.

### C-20261003-1 · 2026-10-03 · CLI beta.12: `status --until-ready` and `wait_for` prove Play mode; `--` fence; `unity setup claude`; Claude Code MCP line corrected
- because: R-20261003-1, R-20261003-2, R-20260922-3 (the MCP mode line still said Claude Code had no `configure` target)
- files: SKILL.md (Step 2 route table: Pipeline install row; JSON note; Step 3 live Editor: verification loop, Play mode; MCP mode; "Skills Unity ships"), RESEARCH.md (header; Current understanding; Open questions; Search plan, Subject and Tooling; R-20261003-1 to 3)
- After a Pipeline install or `editor_play` the skill now waits with `unity status --until-ready` and proves the game runs with `playerLoopTicking`/`frameCount` and `wait_for`, keeping L-006's re-send loop for older CLIs; Pipeline parameters go after `--`; `unity recompile` exit 7 now also covers a dropped request; Unity's plugin installs with `unity setup claude`.

### C-20260929-1 · 2026-09-29 · Live `run_tests` judged by its payload; `set_autotick` persists; Codex plugin route
- because: R-20260929-1, R-20260929-2, R-20260929-3
- files: SKILL.md (Step 3 live Editor: long operations bullet; "Skills Unity ships"), RESEARCH.md (Open questions; Search plan, Testing; R-20260929-1 to 3), evals/evals.json (action-4)
- A live `unity command run_tests` can exit 0 with failed tests, so the skill now reads the payload's failed count; `unity command recompile` returns early, so the blocking `unity recompile` is preferred; the autotick note no longer says the setting resets on a domain reload (the manuals say it persists); the Codex install line for Unity's plugin sits beside the Claude Code one.

### C-20260926-1 · 2026-09-26 · Pipeline 0.8.0-exp.1: capture default, JSON status payloads, 127.0.0.1 only; CLI build listing and `build run`
- because: R-20260926-1
- files: SKILL.md (Step 3 live Editor: screens sentence, status polling bullet, raw HTTP bullet; tests and builds: build line), RESEARCH.md (Current understanding; Open questions; Search plan; R-20260926-1, R-20260926-2)
- Status payloads are now objects, so a double-decode breaks; the capture default changed and Edit Mode support is noted as unverified until a live run; `localhost` no longer reaches the server at all.

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
