# Learnings: unity-agent-headless

Procedural lessons for [SKILL.md](SKILL.md). Research findings live in [RESEARCH.md](RESEARCH.md); every change is logged in [CHANGELOG.md](CHANGELOG.md); test runs in [TESTS.md](TESTS.md); state in `evergreen.json`. Format and write-time gate: MAINTENANCE.md (LEARNINGS-FORMAT). Retired entries go to LEARNINGS-ARCHIVE.md with a reason.

Write an entry the moment a real signal happens: a user correction, the same error twice, a discovered workaround, an environment fact, a stated preference, a failed test or a failure in use. Check existing entries first (add / update / retire / none). Trigger and Hypothesis are required. Promote after three confirmations; retire when harmful > helpful.

## Active

### L-001 · 2026-09-06 · Electron apps (Unity Hub) fail with "Cannot find module '--headless'" from agent shells
- Trigger: `"Unity Hub.exe" -- --headless editors --installed` failed twice (PowerShell tool, then Git Bash) on 2026-09-06 with a Node module-not-found stack trace.
- Hypothesis: Claude Code and VS Code export `ELECTRON_RUN_AS_NODE=1` to child processes, so the Hub started as plain Node and tried to `require('--headless')`.
- Rule: clear the variable for that call (`env -u ELECTRON_RUN_AS_NODE ...` in bash, `Remove-Item Env:ELECTRON_RUN_AS_NODE` in PowerShell) before launching any Electron app from an agent shell.
- Evidence: worked immediately after clearing; C-20260906-1 (SKILL.md §Step 4)
- Scope: env:dev-machine (any agent host that sets the variable)
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-002 · 2026-09-06 · No system .NET SDK on the development machine; Unity's bundled SDK covers the compile check only
- Trigger: `dotnet build` and `dotnet test` reported "No .NET SDKs were found" (2026-09-06) although the repo's AGENTS.md assumes `dotnet test` works. A `dotnet` install with runtimes but no SDK gives exactly this message.
- Hypothesis: the SDK was never installed on that machine (or its install location moved); Unity ships its own SDK 8.0.318 under `Editor\Data\DotNetSdk` for Bee/ILPP.
- Rule: for the csproj compile check use the bundled SDK (the driver does); for a `net9.0` test project say a system SDK is needed (`winget install Microsoft.DotNet.SDK.9`) instead of editing the project's target framework.
- Evidence: C-20260906-1 (SKILL.md §Step 2); R-20260906-3
- Scope: env:dev-machine
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-003 · 2026-09-06 · A `throw` in a `powershell -File` script does not give the caller exit 1
- Trigger: the driver's lock refusal threw as intended, but `$LASTEXITCODE` in the calling PowerShell was 0 (2026-09-06), so a caller branching on exit code would have believed the run succeeded.
- Hypothesis: an unhandled terminating error in `-File` mode prints and ends the script but the host's exit code is not set unless the script calls `exit`.
- Rule: wrap the driver's main in try/catch, put the message into the JSON `notes`, set `ok=false`, and end with an explicit `exit 1`; callers read the JSON, not the stack trace.
- Evidence: fixed in scripts/unity_headless.ps1 the same day; C-20260906-1
- Scope: skill
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06

### L-004 · 2026-09-06 · The driver's compile log is empty on a clean build, so `ok` cannot be quoted from it
- Trigger: `unity_headless.ps1 -Action compile` on a Unity 6 game project (Editor open) returned `ok: true, errorsCS: 0`, but `Logs/agent-compile-20260906-094741.log` held only the two `=== <csproj>` header lines; no `Build succeeded` line to quote (2026-09-06).
- Hypothesis: line 149 runs `dotnet build -v q -clp:NoSummary`; quiet verbosity plus NoSummary prints nothing when there are no diagnostics, so a green run leaves an empty log and `ok` rests on exit code 0 plus the absence of `error CS`.
- Rule: treat the JSON `exitCode` + `errorsCS` as the evidence for a green compile (that is what the driver derives `ok` from), or re-run `dotnet build <csproj> -nologo -v q -clp:"Summary;ErrorsOnly;WarningsOnly"` to get the quotable `Build succeeded. 0 Warning(s) 0 Error(s)` lines. Candidate fix: switch the driver to `-clp:Summary;ErrorsOnly;WarningsOnly` so the log carries the summary.
- Evidence: direct rebuild of both csproj on 2026-09-06 printed `Build succeeded. 0 Warning(s) 0 Error(s)`, EXIT=0, matching the JSON.
- Scope: skill
- Status: promoted (C-20260906-2) · helpful 1 · harmful 0 · last_confirmed 2026-09-06
