# Learnings: unity-agent-workflow

Procedural lessons for [SKILL.md](SKILL.md). Research findings live in [RESEARCH.md](RESEARCH.md); every change is logged in [CHANGELOG.md](CHANGELOG.md); test runs in [TESTS.md](TESTS.md); state in `evergreen.json`. Format and write-time gate: MAINTENANCE.md (LEARNINGS-FORMAT). Retired entries go to LEARNINGS-ARCHIVE.md with a reason.

Write an entry the moment a real signal happens: a user correction, the same error twice, a discovered workaround, an environment fact, a stated preference, a failed test or a failure in use. Check existing entries first (add / update / retire / none). Trigger and Hypothesis are required. Promote after three confirmations; retire when harmful > helpful.

## Active

### L-001 · 2026-09-06 · A repo's "dotnet test works" claim can be false on a given machine
- Trigger: The AGENTS.md of a Unity 6 game project describes `dotnet test` as the fast loop, but on the development machine on 2026-09-06 no .NET SDK was installed and the command failed; the rule's evidence lived on another machine.
- Hypothesis: instruction files record what worked where they were written; toolchain presence is an environment fact, not a repo fact.
- Rule: before promising a verification rung, run the probe (unity-agent-cli) and confirm the tool exists here; report a missing rung instead of skipping silently.
- Evidence: SKILL.md §Step 2 ladder; unity-agent-headless:L-002
- Scope: global
- Status: promoted (C-20260906-1) · helpful 1 · harmful 0 · last_confirmed 2026-09-06
