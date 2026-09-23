---
title: Publish unity-agent as a public repository in the sibling-plugin shape
kind: decision
status: active
date: 2026-09-22
verified: 2026-09-22
tags: [release, repo, privacy, pattern]
summary: read before changing the repo layout, the CLAUDE.md import, the release workflow, or before a first push from a fresh clone
---

# Publish unity-agent as a public repository in the sibling-plugin shape

## Context

The suite grew in a private working folder from 2026-09-06, installed by linking its skill folders into each agent's skills directory, and was shared by mailing a zip. It had no git history.

## Decision

unity-agent is published as the public repository github.com/m4bwav/unity-agent in the shape of the sibling plugins (context-health, obsidian-notes, chartwright, everlast, evergreen-protocol): MIT with the author credit only; `AGENTS.md` as the source of truth, `.github/copilot-instructions.md` pointing at it, and `CLAUDE.md` importing it through Claude Code's `@` import syntax; `.claude-plugin/plugin.json` plus `marketplace.json`; a test workflow (structure checks on Linux and Windows, both PowerShell scripts smoke-tested in PowerShell 7 and 5.1 on a runner with no Unity); a release workflow on `vX.Y.Z` tags; an `ai-docs/` doc set; and one scrubbed first commit at version 1.1.0.

## Reasons

- `git clone` plus links is the whole install, `git pull` the update path, and each evergreen refresh lands as a commit instead of a new zip.
- `CLAUDE.md` imports `AGENTS.md` instead of asking in words: since Claude Code 2.1.277, when a repository has both files Claude reads only `CLAUDE.md`, so a pointer written as prose relies on the model choosing to open the file (code.claude.com/docs/en/memory, read 2026-09-22).
- The public checks (`tests/check_skills.py`) carry only generic guards (absolute home-folder paths, AI attribution). The list of strings removed by the scrub is private by definition, so it lives outside the repository with the owner's notes, and a local pre-push hook runs it against every commit being pushed.

## Alternatives rejected

- Keeping the folder private and mailing zips: every copy carried machine-specific text, and the scripts had to be renamed to get through mail filters.
- A privacy denylist in public CI: it would publish the very names it guards.
- Adding the private names to the owner's global redact list: that list feeds the doc lint of every registered repository, so the private project's own repository would be flagged on every entry.
- Keeping the pre-scrub history: there was none; the first commit is the scrubbed tree.

## Consequences

The local folder stays where it was (the skill links point at it) and becomes the clone. Evidence that named the development machine, a private game project or an account was generalised ("the development machine", "a Unity 6 game project", `dev-machine`); every R-, L-, C- and T- id was kept. A fresh clone needs the local pre-push hook re-created from the owner's notes before its first push.
