# AGENTS.md snippet for a Unity repo

Paste into the repo's `AGENTS.md` (or `CLAUDE.md` / `.github/copilot-instructions.md`, which should just point at `AGENTS.md`). Edit the paths and the project's own build/test entry points; delete rules the repo already states elsewhere.

```markdown
## Working in this Unity project as an agent

- Unity version is pinned in `ProjectSettings/ProjectVersion.txt`; the Editor may be open while you work. Before any Unity action, find out which: run the probe from the `unity-agent-cli` skill or `unity pipeline list`.
- Verify at the lowest rung that can catch the mistake: `dotnet test` (engine-free logic) → `dotnet build Assembly-CSharp.csproj` (whole-assembly compile check, works with the Editor open) → `unity test --mode EditMode|PlayMode` (Editor closed) → live Pipeline commands (`recompile`, `get_console_logs --severity error`, `screenshot`) when the Editor is open with `com.unity.pipeline`.
- Never write or regex-edit `.unity`, `.prefab`, `.asset`, `.mat`, `.controller` YAML, and never touch them while the Editor is open. Change assets through an editor script, an importer, a `[MenuItem]`, `-executeMethod`, or a Pipeline command.
- Every new file under `Assets/` needs a `.meta`; commit and move them together; never regenerate an existing `.meta`.
- Keep gameplay rules in plain C# classes (Humble Object) so the headless tests reach them; MonoBehaviours only wire and render.
- Content lives in text sources read by importers; do not hand-edit generated assets.
- A green `dotnet test` is not a compile check for MonoBehaviours, UI, or `Assets/Editor` code. After a rename or removal, grep all of `Assets` for every affected symbol and run the compile check.
- Don't add asmdefs, packages, DI containers, or Addressables without asking.
- Save-reachable and serialized types: adding a field is safe; renaming or removing one drops data. Flag these changes.
```
