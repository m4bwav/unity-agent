---
title: Scrub a skill suite and guard its pushes: what grep misses, and three escaping traps
kind: solution
status: active
date: 2026-09-22
verified: 2026-09-22
tags: [privacy, scrub, publish, sed, heredoc, changelog]
summary: read before publishing a folder that grew on one machine, or before editing companion files by script (sed \U, heredoc backslashes, the Entry shape template)
---

# Scrub a skill suite and guard its pushes: what grep misses, and three escaping traps

## Problem

A skill suite that grew on one machine carried that machine and a private project in 29 of its files: a personal account, an absolute project path, a hostname in every `evergreen.json`, the project's name about 30 times, its class and asset names in eval prompts, and phrasings such as "verified here" and "on this PC".

## Dead ends

- Grep for the obvious markers finds the paths and the email, not the project's class names, the machine nickname in test headers, or "here" meaning "on my machine". Three readers with different lenses (paths and machines; people and working life; private projects) found 52 to 65 items each, heavily overlapping; merged, that was 64 edits.
- `sed` with a replacement containing `\U` upper-cases the rest of the line (GNU sed): an earlier edit had turned `$env:LOCALAPPDATA\Unity\bin\unity.exe` into `$env:LOCALAPPDATANITYBINNITY.EXE` and shipped unnoticed for two weeks.
- Python run through a shell heredoc from an agent's Bash tool: `\\b` in the source arrived as `\b`, which Python reads as a backspace character, so a regex written into `evals.json` silently lost its word boundary. Write scripts to a file and build backslashes with `chr(92)`, or test the regex after writing.
- Inserting a changelog entry before the first `### C-` lands inside the `Entry shape:` template line that every companion's header quotes. Anchor on the first heading whose id has real digits (`^### C-\d{8}-\d+ ·`).

## Fix

1. Readers report findings as verbatim one-line snippets with a replacement; one script applies them all, asserting each snippet occurs the expected number of times before anything is written.
2. Generalise rather than delete ("the development machine", "a Unity 6 game project", `dev-machine` for the test env label); keep every id.
3. Keep the list of removed strings out of the repository. A local, uncommitted `.git/hooks/pre-push` runs a private check that scans every line the pushed commits add and refuses the push on a hit.
4. Scaffold in the sibling shape, `git init`, one commit, `gh repo create --public --source . --push`, then tag the release.

## Verified by

`python tests/check_skills.py` reports ok for 5 skills; `tests/check_scripts.ps1` passes in PowerShell 7.6 and Windows PowerShell 5.1; the private check reports clean on the tree and catches six planted strings of different kinds, while the author credit passes (2026-09-22).

Related: [the publication decision](../decisions/2026-09-22-publish-unity-agent-as-a-public-repository-in-the-sibling-pl.md)
