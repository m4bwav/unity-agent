# Tests: unity-agent-mcp

Test runs for [SKILL.md](SKILL.md). Cases live in `evals/evals.json`. A failure that taught something is a lesson in [LEARNINGS.md](LEARNINGS.md); a fix it caused is logged in [CHANGELOG.md](CHANGELOG.md) with `because: T-...`; research it triggered is in [RESEARCH.md](RESEARCH.md); counts and the failing list are in `evergreen.json` under `tests`. Rules: MAINTENANCE.md (testing section) and the plugin's `protocol/TESTING.md`.

A test passes on evidence (a tool call in the trace, a file, a marker, a log line), never on the transcript's claim that something was done.

Entry shape: `### T-YYYYMMDD-n · date · harness · env · passed/total`, then one line per failing case (`id · kind · class · what the evidence showed`), then `led to:` (L-, C-, R- ids or none). Newest first. Budget 150 lines; archive older runs to `TESTS-ARCHIVE.md`.

Case added 2026-09-22 and not yet run: action-2 (tools listed through `claude mcp list` or the MCP Inspector CLI), from C-20260922-2.

## Runs

### T-20260906-1 · 2026-09-06 · evergreen-tester subagent (one run per case, not three) · dev-machine Claude Code · 2/2
- trigger-1 pass (skill invoked; official `unity mcp` recommended, IvanMurzak ruled out by the path)
- decoy-2 pass (no unity-agent skill invoked for Todoist)
- Trigger results from a subagent are a proxy for the main loop. Only one run per case was made at creation to bound cost; the suite's `runs: 3` still applies to the next full run. Cases not run: trigger-2, decoy-2 (or decoy-1 for mcp), outcome-1.
- led to: none

