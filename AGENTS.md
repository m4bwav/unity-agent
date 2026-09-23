# Agent rules for unity-agent

Rules for any AI agent (Claude Code, Copilot, Cursor, Codex, Gemini CLI) working in this repository. `CLAUDE.md` and `.github/copilot-instructions.md` only point here.

Read [README.md](README.md) first. The five skills live under [skills/](skills/); each is an evergreen unit with its companions beside it (RESEARCH, CHANGELOG, LEARNINGS, TESTS, `evals/evals.json`, MAINTENANCE, `evergreen.json`).

## Rules

- Evergreen units in pointer mode: before editing a skill read its `evergreen.json`; if `next_due` has passed or `contradiction` is set, say so and refresh after the task (the evergreen plugin's `evergreen-refresh`, otherwise the skill's `MAINTENANCE.md`). Every edit to a SKILL.md gets a CHANGELOG entry with its reason (`R-`, `L-` or `T-` ids, or "user request"); re-run that skill's `evals/evals.json` (evergreen-test) when the change alters what the skill triggers on, decides or does.
- Research beats recall. Unity CLI commands and exit codes, `com.unity.pipeline` versions and MCP server versions move monthly: never change a command, flag, version or exit code from memory; cite the source in RESEARCH.md (an `R-` entry) and log the change in CHANGELOG.md (a `C-` entry).
- `skills/unity-agent-cli/scripts/unity_probe.ps1` and `skills/unity-agent-headless/scripts/unity_headless.ps1` print exactly one JSON object and fail soft. Keep them working in Windows PowerShell 5.1 and PowerShell 7.
- Skills stay under 200 lines with a description of at most 1,024 characters (Agent Skills spec) that says what the skill does and names the sibling that owns nearby requests.
- The skills install nothing on their own: the Unity CLI, the Pipeline package, Unity's own skills, MCP registrations and SDKs are the user's to approve.
- Run `python tests/check_skills.py` from the repository root before committing (structure, companions, manifests, links, and the two public-safety guards). CI runs it on Linux and Windows and smoke-tests both PowerShell scripts on a runner with no Unity installed (`tests/check_scripts.ps1`).
- This is a public repository. Nothing in it names a person other than the author credit, a machine, an absolute path on someone's machine, a private project, or a credential. A lesson learned on a particular machine or project is generalised here ("the development machine", "a Unity 6 game project"); the specifics belong in the owner's private notes, never in a commit.
- Versions: when a packaged file changes, bump `.claude-plugin/plugin.json` and tag `vX.Y.Z`; the release workflow checks the tag against the manifest, runs the checks, zips `skills/` and publishes a GitHub release.
- No AI attribution anywhere: no Co-Authored-By trailers, no "generated with" lines in commits, pull requests or files.

## everlast (session knowledge, load on demand)

- `ai-docs/INDEX.md` lists what past sessions learned here (solutions with verified commands, decisions with reasons, plans). At the start of a task, scan it and open only the entries whose title or tags match; read `ai-docs/HANDOFF.md` when continuing unfinished work (everlast-resume skill).
- Before finishing a task that hit a dead end, verified a non-obvious command, made a design choice, or taught you something about the user, record it (everlast-capture skill, or `everlast.py note` / `handoff`); rewrite `HANDOFF.md` when work is left unfinished. Say "nothing to record" when that is true.
- Anything naming a person, an internal host or name, a credential, or an opinion about people goes to the private sidecar (`--private`), never here. Lessons about the user or this machine go to the user tier (`--user`).
- Link documents together with relative markdown links: every markdown folder has an index that links its files, every entry links its index and the entries it builds on (a `Related:` line). No wikilinks in the repo.
