# Tests: unity-agent-cli

Test runs for [SKILL.md](SKILL.md). Cases live in `evals/evals.json`. A failure that taught something is a lesson in [LEARNINGS.md](LEARNINGS.md); a fix it caused is logged in [CHANGELOG.md](CHANGELOG.md) with `because: T-...`; research it triggered is in [RESEARCH.md](RESEARCH.md); counts and the failing list are in `evergreen.json` under `tests`. Rules: MAINTENANCE.md (testing section) and the plugin's `protocol/TESTING.md`.

A test passes on evidence (a tool call in the trace, a file, a marker, a log line), never on the transcript's claim that something was done.

Entry shape: `### T-20261003-1 · 2026-10-03 · evergreen-tester subagents (trigger cases after the beta.12 refresh, one run each) · Windows 11 dev machine, no Editor started · 2/2
- trigger-1 pass (Skill called; read-only probe and `unity status`: CLI 1.0.0-beta.12 found, the game project's Editor open and ready, Pipeline 0.6.0-exp.1 reachable)
- decoy-1 pass (unity-agent-mcp invoked, not unity-agent-cli)
- Action cases (Play-mode `--until-ready` and `wait_for` loop) need a live Editor on CLI beta.12; not run. Trigger results from a subagent are a proxy for the main loop.
- led to: none

### T-YYYYMMDD-n · date · harness · env · passed/total`, then one line per failing case (`id · kind · class · what the evidence showed`), then `led to:` (L-, C-, R- ids or none). Newest first. Budget 150 lines; archive older runs to `TESTS-ARCHIVE.md`.

Cases added 2026-09-22 and not yet run: action-2 (the compile loop) and action-3 (the command manifest), from C-20260922-2.

## Runs

### T-20260926-1 · 2026-09-26 · evergreen-tester subagents (partial suite after the Pipeline 0.8 refresh) · Windows 11 dev machine, CLI 1.0.0-beta.8, no Editor running · 2/2 graded (1 not gradable)
- trigger-1 pass (Skill called; probe and `unity status` read-only; answer named both editors and that the user's game project (6000.6.0f1) was not open)
- decoy-1 pass (unity-agent-cli not invoked); the run found unity-agent-mcp missing from the skill listing: its ~/.claude/skills junction had never been made (fixed 2026-09-26)
- action-2 not gradable: no Editor running; the skill probed, got STATUS_NO_INSTANCES (exit 6), stopped and offered the offline compile check; needs a live Editor on Pipeline 0.8 to grade (also the object-payload parse of `recompile_status`)
- led to: none (C-20260926-1 was the refresh itself)

### T-20260906-1 · 2026-09-06 · evergreen-tester subagent (one run per case, not three) · dev-machine Claude Code · 3/3
- trigger-1 pass (skill invoked; probe ran)
- decoy-1 pass (unity-agent-mcp invoked instead)
- action-1 pass (probe + `unity pipeline list` in trace); baseline without the skill reached the CLI via `unity status` after 8 commands, so the evidence rule was tightened (C-20260906-2)
- Trigger results from a subagent are a proxy for the main loop. Only one run per case was made at creation to bound cost; the suite's `runs: 3` still applies to the next full run. Cases not run: trigger-2, decoy-2 (or decoy-1 for mcp), outcome-1.
- led to: C-20260906-2

