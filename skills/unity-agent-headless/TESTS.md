# Tests: unity-agent-headless

Test runs for [SKILL.md](SKILL.md). Cases live in `evals/evals.json`. A failure that taught something is a lesson in [LEARNINGS.md](LEARNINGS.md); a fix it caused is logged in [CHANGELOG.md](CHANGELOG.md) with `because: T-...`; research it triggered is in [RESEARCH.md](RESEARCH.md); counts and the failing list are in `evergreen.json` under `tests`. Rules: MAINTENANCE.md (testing section) and the plugin's `protocol/TESTING.md`.

A test passes on evidence (a tool call in the trace, a file, a marker, a log line), never on the transcript's claim that something was done.

Entry shape: `### T-YYYYMMDD-n · date · harness · env · passed/total`, then one line per failing case (`id · kind · class · what the evidence showed`), then `led to:` (L-, C-, R- ids or none). Newest first. Budget 150 lines; archive older runs to `TESTS-ARCHIVE.md`.

## Runs

### T-20260906-1 · 2026-09-06 · evergreen-tester subagent (one run per case, not three) · dev-machine Claude Code · 3/3
- trigger-1 pass (driver `-Action compile` ran, ok:true)
- decoy-1 pass (unity-agent-packages invoked instead)
- action-1 covered by trigger-1's trace (same prompt shape); baseline without the skill found the bundled SDK by hand after 2 min and built 0 errors, so the evidence rule was tightened (C-20260906-2). Tester found the empty compile log (L-004, fixed)
- Trigger results from a subagent are a proxy for the main loop. Only one run per case was made at creation to bound cost; the suite's `runs: 3` still applies to the next full run. Cases not run: trigger-2, decoy-2 (or decoy-1 for mcp), outcome-1.
- led to: L-004, C-20260906-2

