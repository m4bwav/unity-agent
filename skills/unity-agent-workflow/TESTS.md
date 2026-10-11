# Tests: unity-agent-workflow

Test runs for [SKILL.md](SKILL.md). Cases live in `evals/evals.json`. A failure that taught something is a lesson in [LEARNINGS.md](LEARNINGS.md); a fix it caused is logged in [CHANGELOG.md](CHANGELOG.md) with `because: T-...`; research it triggered is in [RESEARCH.md](RESEARCH.md); counts and the failing list are in `evergreen.json` under `tests`. Rules: MAINTENANCE.md (testing section) and the plugin's `protocol/TESTING.md`.

A test passes on evidence (a tool call in the trace, a file, a marker, a log line), never on the transcript's claim that something was done.

Entry shape: `### T-YYYYMMDD-n · date · harness · env · passed/total`, then one line per failing case (`id · kind · class · what the evidence showed`), then `led to:` (L-, C-, R- ids or none). Newest first. Budget 150 lines; archive older runs to `TESTS-ARCHIVE.md`.

## Runs

### T-20261011-1 · 2026-10-11 · claude plugin eval 2.1.281 (default model, 1 run per case, --ablation none) · Windows 11 native, no Editor running · 4/4
- Suite: cases from `evals/evals.json` exported with `evergreen.py eval-export --out evals/<short name>` into an uncommitted root `evals/` tree, frontmatter `runs` set to 1; `claude plugin eval . --ablation none --no-publish -j 4 --trust-plugin --case "*trigger*"`, then `"*decoy*"`. Cost for all four units: trigger 0.88 USD (28 s), decoy 0.49 USD (15 s), act-suffix decoys 0.72 USD plus a 0.27 USD rerun.
- trigger-1 (latest thinking on agents with Unity), trigger-2 (keep agents from breaking scenes and .meta files) · trigger · pass · `Skill(unity-agent-workflow)` called.
- decoy-1 (which editors are installed, is the editor open), decoy-2 (sprite with ComfyUI) · trigger · pass · unity-agent-workflow not called.
- decoy-1-act · pass, unity-agent-cli called instead (1 of 1). decoy-2-act · pass, unity-agent-workflow not called.
- Harness finding: the exported decoy prompts end with "say how you would approach it ... do not carry it out", so every decoy ran one turn with no tool call and passed trivially. To test the sibling overlap for real, each decoy was run again as `<id>-act` with the trigger suffix ("start the job, stop after two or three tool calls") and, for sibling decoys, a second `tool_used` grader for the sibling skill.
- Not run: action and outcome cases (they grant Bash, which native Windows refuses in eval; not required for this pass). Evidence is the harness's `tool_used` grader on the run trace. One run per case, not the suite's `runs: 3`.
- led to: none

### T-20260906-1 · 2026-09-06 · evergreen-tester subagent (one run per case, not three) · dev-machine Claude Code · 2/2
- trigger-1 pass (skill invoked; ladder and repo rules cited)
- decoy-1 pass (unity-agent-cli invoked instead)
- Trigger results from a subagent are a proxy for the main loop. Only one run per case was made at creation to bound cost; the suite's `runs: 3` still applies to the next full run. Cases not run: trigger-2, decoy-2 (or decoy-1 for mcp), outcome-1.
- led to: none

