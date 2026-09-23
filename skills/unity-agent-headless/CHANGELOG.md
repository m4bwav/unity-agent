# Changelog: unity-agent-headless

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20260922-1 · 2026-09-22 · Privacy scrub before the repository went public
- because: user request (publish the suite as a public repository); three privacy readers (paths and machines, people and working life, private projects)
- files: SKILL.md (Hub path example now the default install location), RESEARCH.md (Current understanding; R-20260906-3 sources), LEARNINGS.md (L-001, L-002, L-004), evals/evals.json (three prompts), TESTS.md (T-20260906-1 env), evergreen.json (tests env), scripts/unity_headless.ps1 (example paths)
- The private game project, the development machine's name and machine history were generalised ("a Unity 6 game project", "the development machine", `dev-machine`); every id kept.

### C-20260906-2 · 2026-09-06 · Compile log now carries the build summary; approved-verb function names; action-1 evidence tightened
- because: T-20260906-1, L-004
- files: scripts/unity_headless.ps1 (compile branch), evals/evals.json (action-1)
- `dotnet build` runs at `-v minimal` instead of `-v q -clp:NoSummary`, so a clean build leaves `Build succeeded` in `Logs/agent-compile-*.log` and the JSON `ok` has a quotable line behind it; `Parse-Log`/`Run-Unity` renamed to `Read-UnityLog`/`Invoke-Unity`. The baseline reached the bundled SDK by hand after two minutes, so the case now requires the driver or its log.

### C-20260906-1 · 2026-09-06 · Created as an evergreen unit (pointer mode) with the headless driver
- because: user request; R-20260906-1, R-20260906-2, R-20260906-3; L-001, L-002, L-003
- files: SKILL.md (all sections), scripts/unity_headless.ps1, RESEARCH.md, LEARNINGS.md, TESTS.md, evals/evals.json, evergreen.json
- Initial version. Tier `moderate`, interval 30d. Cheapest-check table, compile check via Unity-generated csproj and the Unity-bundled .NET SDK, batchmode flags and log markers for Unity 6, UTF CLI, Hub CLI fallback with the ELECTRON_RUN_AS_NODE fix. The driver wraps compile/tests/method with lock detection and JSON evidence.
