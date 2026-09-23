# Handoff

## Current state

- Published 2026-09-22 as github.com/m4bwav/unity-agent, version 1.1.0: one scrubbed commit, tag v1.1.0 for the release workflow.
- unity-agent-cli and unity-agent-mcp were refreshed the same day (cli: Pipeline 0.7 removed `get_console_logs`, the verification loop now uses `unity recompile` and `console`; mcp: Pipeline 0.7 and CLI beta.11, local scope for Claude Code, CoplayDev tool groups, Inspector CLI evidence). Next due: cli 2026-09-26, mcp 2026-09-30; headless, packages and workflow per their `evergreen.json`.

## In progress

- None.

## Decisions made this session

- Sibling-plugin shape, `CLAUDE.md` imports `AGENTS.md`, private removed-strings list kept outside the repo with a local pre-push hook: [decision](decisions/2026-09-22-publish-unity-agent-as-a-public-repository-in-the-sibling-pl.md).

## Dead ends hit

- `sed` `\U`, heredoc backslashes and the Entry shape template: [solution](solutions/2026-09-22-scrub-a-skill-suite-and-guard-its-pushes-what-grep-misses-an.md).

## Next single action

Run the three eval cases added on 2026-09-22 and not yet run (unity-agent-cli action-2 and action-3, unity-agent-mcp action-2) with evergreen-test against a live Editor on CLI beta.11 or later, and record the T- entries.
