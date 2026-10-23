# Changelog: unity-agent-workflow

Every change to [SKILL.md](SKILL.md) and its companions, newest first, each with the reason. Reasons cite findings in [RESEARCH.md](RESEARCH.md) (`R-`), lessons in [LEARNINGS.md](LEARNINGS.md) (`L-`), and test runs in [TESTS.md](TESTS.md) (`T-`). State in `evergreen.json`. Protocol: MAINTENANCE.md.

Entry shape: `### C-YYYYMMDD-n · date · one-line summary`, then `because:` (IDs or "user request"), `files:` (file and section), and a sentence on what changed. Cite section headings, not line numbers.

### C-20261023-1 · 2026-10-23 · Game design before code: references/game-design.md and a new Step 4
- because: user request (book-learnings track 9, after Rogers, *Level Up!*); R-20261023-1; T-20261023-1
- files: references/game-design.md (new), SKILL.md (description; new Step 4; Steps 4 and 5 renumbered 5 and 6; Output), evals/evals.json (trigger-3, trigger-4, decoy-3, decoy-4, action-2), LEARNINGS.md (L-003)
- New page: the one-pager and the feature-fit check, the beat chart and what to read across it, player metrics in one `PlayerMetrics` ScriptableObject, `_Playground` and `_CombatArena` scenes, cheats compiled out (built-in `DEVELOPMENT_BUILD` or a custom symbol in the development build profile), the enemy card, encounter, fairness and boss rules, the Cinemachine 3 component names with the 2.x names they replaced, a camera checklist with a PlayMode test, the attack matrix as data, and a playtest protocol and questionnaire. Step 4 points at it for game features. The description gained game-design trigger words and lost the repo-setup parenthesis to stay under 1,024 characters; all eight trigger and decoy cases were rerun.
### C-20261017-2 · 2026-10-17 · references/3d-models.md: 3D models from the Unity developer's side
- because: user request: each plugin carries 3D modelling knowledge for its topic and points to polywright; R-20261017-1
- files: references/3d-models.md (new), SKILL.md (Step 3, the 3D-models bullet gains one pointer sentence), RESEARCH.md (R-20261017-1)
- New reference page: formats and importers (FBX chain, glTFast 6.14 limits), Model tab settings, Rig and animation, LOD Group naming and Mesh LOD, URP and HDRP texture packing, Unity 6.6 draw-call guidance (SRP Batcher plus GPU Resident Drawer, static batching off), collision, modelling styles, kits and texel density, naming, AssetPostprocessor, import verification; links polywright's contract and its Unity page. Pointer only in SKILL.md; no trigger or description changed, so the evals were not re-run.

### C-20261017-1 · 2026-10-17 · 3D models come from polywright through its asset folder
- because: user request (polywright HANDOFF owed item 6: siblings call polywright through the folder contract)
- files: SKILL.md (Step 3, new bullet after the content-importer bullet)
- One bullet: when polywright is installed, a model that must be made, found, captured or fixed is requested through polywright's asset-folder contract with the `game-unity` target, and the file named in `manifest.json` is imported from `out/`. Pointer only; no trigger or description changed, so the evals were not re-run.

### C-20261011-1 · 2026-10-11 · Agentic-access terms, Unity 7 alpha facts, skill-pack adoption, benchmark wording
- because: R-20261011-1
- files: SKILL.md (Step 4: skill packs, Unity's agentic path, benchmarks; Step 5: terms), RESEARCH.md (one finding)
- Step 5 names the "Authorized Agentic Access" clauses with Unity's informal reading; Step 4 has install counts and the Unity 7 alpha facts.

### C-20261006-1 · 2026-10-06 · Hand-written .meta rules for sliced sprites; rung 4 commands brought up to Pipeline 0.7
- because: L-002 (a settlement game's sprite-sheet workflows); unity-agent-cli R-20260922-1 (Pipeline 0.7.0-exp.1 removed `get_console_logs`) and unity-agent-cli L-004 (`screenshot` renders the camera only)
- files: SKILL.md (Step 2 ladder, rung 4; Step 3, .meta bullet), LEARNINGS.md (L-002), evergreen.json (counts)
- The .meta bullet now says a replaced asset keeps its .meta and points at L-002 for hand-written sprite sheets; rung 4 names the commands that exist on current Pipeline versions. Out-of-cycle edit; no trigger changed, so the evals were not re-run.

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
