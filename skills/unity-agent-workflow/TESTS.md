# Tests: unity-agent-workflow

Test runs for [SKILL.md](SKILL.md). Cases live in `evals/evals.json`. A failure that taught something is a lesson in [LEARNINGS.md](LEARNINGS.md); a fix it caused is logged in [CHANGELOG.md](CHANGELOG.md) with `because: T-...`; research it triggered is in [RESEARCH.md](RESEARCH.md); counts and the failing list are in `evergreen.json` under `tests`. Rules: MAINTENANCE.md (testing section) and the plugin's `protocol/TESTING.md`.

A test passes on evidence (a tool call in the trace, a file, a marker, a log line), never on the transcript's claim that something was done.

Entry shape: `### T-YYYYMMDD-n · date · harness · env · passed/total`, then one line per failing case (`id · kind · class · what the evidence showed`), then `led to:` (L-, C-, R- ids or none). Newest first. Budget 150 lines; archive older runs to `TESTS-ARCHIVE.md`.

## Runs

### T-20261023-1 · 2026-10-23 · headless `claude -p` 2.1.281 (default model, 3 runs per case), `--setting-sources project`, `--plugin-dir` on the books-9 worktree · Windows 11 native, no Editor running · 27/27
- Each run in its own empty folder (action runs: an empty `Assets/Scripts`); trigger and decoy runs `--max-turns 3`; `--permission-mode acceptEdits`. Grader reads the stream-json trace (Skill calls) and, for action-2, the files left behind: `docs/ONE-PAGER.md` exists and a `.cs` file declares `: ScriptableObject`.
- trigger-1, trigger-2, trigger-3 (plan a twin-stick shooter's first level and enemies), trigger-4 (playtest plan for a platformer) · trigger · 12/12 · `Skill(unity-agent:unity-agent-workflow)` called.
- decoy-1 · 3/3, unity-agent-cli called instead. decoy-2 (ComfyUI sprite), decoy-3 (Roblox waves), decoy-4 (board-game pitch) · 9/9, no Skill call.
- action-2 (set up a fox platformer's run and jump) · with the skill 3/3: every run wrote `docs/ONE-PAGER.md` with the core loop and a `PlayerMetrics` ScriptableObject read by the controller and an engine-free test project (two runs also wrote an editor script that builds the scene). Baseline (no plugin) 0/3: controllers with the numbers as serialized fields on the MonoBehaviour, no one-pager. The baseline outputs are the grader's wrong-answer check; a with-run is its right-answer check.
- Not rerun after the prose edits to references/game-design.md (wording only; Step 4 and the description unchanged). outcome-1 and action-1 not run (unchanged behaviour).
- led to: L-003
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

