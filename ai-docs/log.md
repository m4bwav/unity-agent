# Log

Append-only. One line per operation: `## [YYYY-MM-DD] op | title` where op is one of add, update, supersede, prune, handoff, index. Newest at the bottom. Never edited, only appended; this is the history the entries themselves do not carry.

## [2026-09-22] init | scaffolded
## [2026-09-22] add | decision: Publish unity-agent as a public repository in the sibling-plugin shape
## [2026-09-22] add | solution: Scrub a skill suite and guard its pushes: what grep misses, and three escaping traps
## [2026-09-22] handoff | 20 lines
## [2026-09-22] update | scrubbed and published as github.com/m4bwav/unity-agent 1.1.0; cli and mcp refreshed
## [2026-09-26] update | unity-agent-cli refresh (C-20260926-1, R-20260926-1/-2): Pipeline 0.8.0-exp.1 (capture default screen, *_status payloads are JSON objects, 127.0.0.1 only, settings in Project Settings > Pipeline > Editor), CLI beta.10 build listing and build run; partial suite T-20260926-1 (trigger and decoy pass, action-2 needs a live Editor); unity-agent-mcp had no ~/.claude/skills junction since it was added, so no session could load it: junction created
