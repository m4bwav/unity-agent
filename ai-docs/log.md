# Log

Append-only. One line per operation: `## [YYYY-MM-DD] op | title` where op is one of add, update, supersede, prune, handoff, index. Newest at the bottom. Never edited, only appended; this is the history the entries themselves do not carry.

## [2026-09-22] init | scaffolded
## [2026-09-22] add | decision: Publish unity-agent as a public repository in the sibling-plugin shape
## [2026-09-22] add | solution: Scrub a skill suite and guard its pushes: what grep misses, and three escaping traps
## [2026-09-22] handoff | 20 lines
## [2026-09-22] update | scrubbed and published as github.com/m4bwav/unity-agent 1.1.0; cli and mcp refreshed
## [2026-09-26] update | unity-agent-cli refresh (C-20260926-1, R-20260926-1/-2): Pipeline 0.8.0-exp.1 (capture default screen, *_status payloads are JSON objects, 127.0.0.1 only, settings in Project Settings > Pipeline > Editor), CLI beta.10 build listing and build run; partial suite T-20260926-1 (trigger and decoy pass, action-2 needs a live Editor); unity-agent-mcp had no ~/.claude/skills junction since it was added, so no session could load it: junction created
## [2026-10-03] update | 1.2.1 prepared for the Claude plugin directory: plugin.json homepage, documentationUrl, supportUrl, privacyPolicyUrl; README Privacy section (scripts make no network calls; the probe reads the Pipeline descriptor, which holds a local token it never prints or uses); launcher commands pinned (skills@1.7.0, @modelcontextprotocol/inspector@2.9.0, both run); the CLI install step leads with winget instead of piping Unity's script into the shell
## [2026-10-04] update | the plugin icon (icon.png in .claude-plugin) for the Claude directory, chosen from two Z-Image candidates. Z-Image Turbo bf16, 9 steps, cfg 1, res_multistep/simple, seed 2668718296, prompt "flat vector app icon, bold simple shapes, minimal, centered single motif, thick clean outlines, high contrast, readable at small size, no text, no letters, no numbers, no words, no logos, square composition, a small friendly robot holding a game controller, white and orange on dark grey background"; white corners painted to the background (72, 73, 72)
