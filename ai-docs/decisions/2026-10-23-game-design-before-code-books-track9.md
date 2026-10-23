---
title: Game design before code in unity-agent-workflow (book-learnings track 9)
kind: decision
status: active
date: 2026-10-23
verified: 2026-10-23
tags: [game-design, unity-agent-workflow, evals, cinemachine, books]
summary: read before changing references/game-design.md, the workflow description, or the branch eval set-up
---

# Game design before code in unity-agent-workflow (book-learnings track 9)

Related: [INDEX](../INDEX.md). The change is C-20261023-1 in [the skill's CHANGELOG](../../skills/unity-agent-workflow/CHANGELOG.md); the runs are T-20261023-1 in its [TESTS](../../skills/unity-agent-workflow/TESTS.md).

## Context

A reading of Rogers, *Level Up!* (3rd ed.) proposed design-before-code guidance for the game plugins. The workflow skill covered how an agent verifies Unity work, but nothing on designing the game: no one-pager, metrics, enemy rules, camera checklist or playtest protocol.

## Rulings

- U1. One reference page and one SKILL.md step, not a new skill. A new skill costs a listing line in every session, and "how to work in a Unity repo" is already this skill's job.
- U2. The description had 21 characters left. It gained the game-design trigger words and lost the repo-setup parenthesis (AGENTS.md snippet, skill packs, .gitignore, csproj generation) and "importers over hand-edited assets"; those stay in the body. Every trigger and decoy case was rerun (12/12, 12/12).
- U3. Cheats: the built-in `DEVELOPMENT_BUILD` and `UNITY_EDITOR` symbols first, a custom symbol in the development build profile second. The proof is a release compile, not the define list.
- U4. The book's numbers (mobile session 2-5 minutes, corridors about five hero widths, every ability by three quarters of the way) are kept only as marked heuristics. No real Unity game data exists here to calibrate a design rule, so no measured check was built.
- U5. The C# on the page compiles against the Unity 6000.6.6f1 Editor's assemblies (C# 9). The camera PlayMode test has not been run in a Unity project; the page says so.
- U6. Branch evals run headless with `--setting-sources project`, so the user-level skill links to the main clone do not load beside the branch copy (L-003).

## Not done

- A beat-chart or one-pager lint script: no field a planner sets exists yet, and the rules read as review prompts.
- Multiplayer map rules: they belong to the Roblox sibling, where most games are multiplayer.
- Version bump and tag: left for the owner (plugin stays 1.2.4, change unreleased).
