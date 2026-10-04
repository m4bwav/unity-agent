# Changelog: unity-agent-workflow

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20261003-1 · 2026-10-03 · Skill-pack command pinned to skills 1.7.0
- because: user request (Claude plugin directory submission)
- files: SKILL.md (skill packs)
- The Claude plugin directory wants every package a launcher runs pinned. `npx skills@1.7.0 add` names the current release (`npm view`, 2026-10-03); its help still lists `add <package>`.

### C-20260922-2 · 2026-09-22 · Description trimmed to the Agent Skills 1,024-character limit
- because: agentskills.io/specification (read 2026-09-22: `description` "Must be 1-1024 characters"); caught by the new `tests/check_skills.py`
- files: SKILL.md (frontmatter description, 1,136 to 1,003 characters)
- Same triggers and sibling routing; dropped the Unity-Technologies/skills mention (the body keeps it) and tightened phrasing. Trigger cases not re-run: the trigger phrases are unchanged.

### C-20260922-1 · 2026-09-22 · Privacy scrub before the repository went public
- because: user request (publish the suite as a public repository); three privacy readers (paths and machines, people and working life, private projects)
- files: RESEARCH.md (Current understanding; R-20260906-4 source line), LEARNINGS.md (L-001), CHANGELOG.md (C-20260906-2), evals/evals.json (a decoy prompt and its note), TESTS.md (T-20260906-1 env), evergreen.json (tests env)
- The private game project, the development machine's name and machine history were generalised ("a Unity 6 game project", "the development machine", `dev-machine`); every id kept.

### C-20260906-2 · 2026-09-06 · Added the "no pre-existing red tests, no tautological tests" rule
- because: R-20260906-4
- files: SKILL.md §Step 2
- New rule paragraph before the compile-check rule. Out-of-cycle edit; schedule unchanged (magnitude 0.2). Mirrored into the source game project's AGENTS.md.

### C-20260906-1 · 2026-09-06 · Created as an evergreen unit (pointer mode) with the AGENTS.md snippet
- because: user request; R-20260906-1, R-20260906-2, R-20260906-3
- files: SKILL.md (all sections), references/AGENTS-snippet.md, RESEARCH.md, LEARNINGS.md, TESTS.md, evals/evals.json, evergreen.json
- Initial version. Tier `moderate`, interval 30d. Verification ladder, agent-safety rules for Unity repos, skill-pack pointers, Unity's AI policy summary, and a paste-ready AGENTS.md snippet.
