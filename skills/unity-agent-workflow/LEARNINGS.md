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

### L-002 · 2026-10-06 · `hand-written-sprite-meta`: a hand-written sliced-sprite .meta must keep every identity Unity stores in it
- Trigger: a settlement game's asset skills (seen 2026-10-06) write sprite-sheet `.meta` files by hand with the Editor closed, for crop growth strips, animal sheets and animated building tiles, and record what made them import cleanly and keep tiles and animations working after a sheet was regenerated.
- Hypothesis: tiles, animation clips and prefabs reference a sprite by the texture's GUID plus the sprite's `internalID` (its fileID), and code that sorts frames by name sees the names in the `.meta`; a regenerated `.meta` with new values breaks every reference silently, and a per-frame tight rect moves a center pivot from frame to frame.
- Rule: start from a neighbour's `.meta` of the same kind. New file: a fresh 32-hex GUID (`python -c "import uuid; print(uuid.uuid4().hex)"`), grepped across the repo for a collision. Multiple-sprite mode (`spriteMode: 2`): rename every sprite in both `internalIDToNameTable` and the `spriteSheet.sprites` list, give them sequential `internalID`s that match the name table and a unique 32-hex `spriteID` each, and give every frame of one animation the same rect size (the union of the frames' bounds) so a center pivot does not bob. Regenerating an existing sheet: change the image only, keep the GUID and every `internalID`. Single-sprite textures expose their sprite as fileID `21300000`. Write LF endings with a trailing newline, then let the Editor import it and prove the import by loading the asset (unity-agent-cli L-011).
- Evidence: the game's crop, building and animal sprite skills (recorded there as importing cleanly); SKILL.md §Step 3 (.meta rule)
- Scope: global
- Status: active · helpful 1 · harmful 0 · last_confirmed 2026-10-06
