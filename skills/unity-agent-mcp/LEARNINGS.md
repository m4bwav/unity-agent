# Learnings: unity-agent-mcp

Procedural lessons for [SKILL.md](SKILL.md). Research findings live in [RESEARCH.md](RESEARCH.md); every change is logged in [CHANGELOG.md](CHANGELOG.md); test runs in [TESTS.md](TESTS.md); state in `evergreen.json`. Format and write-time gate: MAINTENANCE.md (LEARNINGS-FORMAT). Retired entries go to LEARNINGS-ARCHIVE.md with a reason.

Write an entry the moment a real signal happens: a user correction, the same error twice, a discovered workaround, an environment fact, a stated preference, a failed test or a failure in use. Check existing entries first (add / update / retire / none). Trigger and Hypothesis are required. Promote after three confirmations; retire when harmful > helpful.

## Active

### L-001 · 2026-09-06 · Project paths with spaces rule out IvanMurzak/Unity-MCP
- Trigger: while ranking servers on 2026-09-06 the README's known constraint ("project path must not contain spaces") was checked against the local project path, which contains spaces (like `D:\My Unity Projects\My Game`).
- Hypothesis: the server passes the path unquoted to a child process.
- Rule: before recommending a community server, compare its path and version constraints with the actual project path and Unity version; say which ones are excluded and why.
- Evidence: SKILL.md §Step 2 server table (Notes column); R-20260906-2
- Scope: global (any project path with spaces)
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06
