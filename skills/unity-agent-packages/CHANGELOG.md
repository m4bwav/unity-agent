# Changelog: unity-agent-packages

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20260922-2 · 2026-09-22 · Repaired the live-Editor row, mangled by an earlier `\U` escape
- because: found by the privacy readers while reviewing the file (not a privacy issue)
- files: SKILL.md (Step table, the open-Editor row)
- `"$env:LOCALAPPDATANITYBINNITY.EXE"` and `UNITY COMMAND PACKAGE_ADD` were an earlier sed replacement whose `\U` upper-cased the rest of the text; restored to `"$env:LOCALAPPDATA\Unity\bin\unity.exe"` and `unity command package_add`. The row has read wrong since 2026-09-06.

### C-20260922-1 · 2026-09-22 · Privacy scrub before the repository went public
- because: user request (publish the suite as a public repository); three privacy readers (paths and machines, people and working life, private projects)
- files: RESEARCH.md (the example manifest), evals/evals.json (two prompts), TESTS.md (T-20260906-1 env), evergreen.json (tests env)
- The private game project, the development machine's name and machine history were generalised ("a Unity 6 game project", "the development machine", `dev-machine`); every id kept.

### C-20260906-2 · 2026-09-06 · Route table names the CLI's full-path fallback
- because: T-20260906-1 (two runs concluded the CLI was absent because `unity` was not on PATH yet)
- files: SKILL.md §Step 2
- The open-Editor row now says to check with `unity pipeline list` and to call the binary under LOCALAPPDATA by full path when it is not on PATH.

### C-20260906-1 · 2026-09-06 · Created as an evergreen unit (pointer mode) with the vendored installer script
- because: user request; R-20260906-1, R-20260906-2
- files: SKILL.md (all sections), references/PackageInstaller.cs, RESEARCH.md, LEARNINGS.md, TESTS.md, evals/evals.json, evergreen.json
- Initial version. Tier `moderate`, interval 30d. Route table by Editor state, the Client API poll pattern, verification steps, AI-package version traps.
