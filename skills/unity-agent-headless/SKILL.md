---
name: unity-agent-headless
description: "Run Unity without opening the Editor window and prove the result from logs: batchmode -executeMethod passes, Unity Test Framework runs from the command line (-runTests, NUnit XML), an offline C# compile check that works even while the Editor is open (dotnet build on Unity's generated csproj using the .NET SDK bundled inside every Unity install), Editor and build log locations, exit-code traps, the project lockfile, and the deprecated Unity Hub headless CLI as a fallback. Use whenever the user asks to build, test, import, or run something in Unity headlessly, in batch mode, from a script or CI, wants to know if the code compiles without opening Unity, asks where the Editor log is, why a batchmode run returned 0 with errors, why 'dotnet test' says no SDK, or says 'refresh unity-agent-headless' / 'is unity-agent-headless stale'. Driving a running Editor through the official CLI is unity-agent-cli; choosing an MCP server is unity-agent-mcp."
---

# Unity headless (batchmode, tests, compile check, logs)

Outcome: a headless Unity or dotnet run whose success is read from the log, the results XML,
or the compiler output, with the exact file path quoted, never from the exit code alone.

## Step 0: freshness (every use, one read)

Read `evergreen.json` next to this file. If `verify_at_use` is true, re-check the listed `volatile_claims` before relying on them. If `contradiction` is set or today is on or after `next_due`, tell the user in one line, do the task with the current content, then run the refresh (`evergreen-refresh`) in the same session. If `tests.failing` is non-empty, say so in one line and run `evergreen-tune` after the task. Never block the task on a refresh unless the task depends on the stale claim.

## Step 1: choose the cheapest check that answers the question

| Question | Run | Editor may be open? |
|---|---|---|
| Does the C# compile? | `unity_headless.ps1 -Action compile` (dotnet build of the Unity-generated `*.csproj`) | yes, about 3 s |
| Does the engine-free logic pass? | the repo's own `dotnet test` project, if it has one | yes |
| Do Unity Test Framework tests pass? | `-Action tests` (batchmode `-runTests`) or `unity test` from unity-agent-cli | no |
| Run an Editor method (importer, build, generator)? | `-Action method -Method Class.Method` (batchmode `-executeMethod`) | no |
| Which editors exist, install one, without the `unity` binary? | Hub headless CLI (Step 4) | yes |

The driver:

```powershell
powershell -NoProfile -File "<this folder>\scripts\unity_headless.ps1" -Project "<abs path>" -Action compile|tests|method [-Method Class.Method] [-TestPlatform EditMode|PlayMode] [-TestFilter <regex>] [-TimeoutSec 1800]
```

It finds the pinned editor from `ProjectSettings/ProjectVersion.txt`, refuses batchmode while a running Editor owns `Temp/UnityLockfile` (removes the file when no process owns it), writes each log to `<project>/Logs/agent-<action>-<stamp>.log`, parses it, and prints one JSON object with `ok`, `exitCode`, `errorsCS`, `compilerErrors`, `exitedCleanly`, `tests` (`total`, `passed`, `failed`, `skipped` from the NUnit XML) and the paths. Read that JSON; do not re-derive.

## Step 2: the compile check (the fast loop)

Unity writes `Assembly-CSharp.csproj` and `Assembly-CSharp-Editor.csproj` at the project root when the project has been opened in an IDE (Edit > Preferences > External Tools > Generate .csproj files). They are SDK-style, target `netstandard2.1`, and reference the engine DLLs by absolute path, so a plain `dotnet build` compiles the whole player assembly in seconds without touching the Editor, and it works while the Editor is open.

Which `dotnet`: a system .NET SDK if `dotnet --list-sdks` lists one; otherwise the SDK every Unity 6 install ships at `<editor>\Editor\Data\DotNetSdk\dotnet.exe` (8.0.x). The driver picks this automatically. That bundled SDK can only build projects targeting `net8.0` or lower: a repo test project on `net9.0` needs a system SDK (install one with `winget install Microsoft.DotNet.SDK.9`, and say so instead of silently downgrading the project).

Limits to state when reporting: the csproj is a snapshot from the last Editor sync (new files added outside the Editor are missing until Unity regenerates it, so add `<Compile Include>` lines or open the project), and a green build says nothing about serialization, scenes, or assets.

## Step 3: batchmode and what to read afterwards

Direct invocation, when the driver or `unity run` do not fit:

```
"<editor>\Editor\Unity.exe" -batchmode -nographics -quit -projectPath "<project>" -executeMethod Class.Method -logFile "<project>\Logs\agent.log"
```

- Unity 6 writes the Editor log per project at `<project>/Logs/Editor.log`; the global `%LOCALAPPDATA%\Unity\Editor\Editor.log` is used only with `-useGlobalLog`. UPM: `<project>/Logs/upm.log`. Licensing: `%LOCALAPPDATA%\Unity\Unity.Licensing.Client.log`.
- Success marker: `Exiting batchmode successfully`. Failure markers: `error CS`, `Scripts have compiler errors`, `Aborting batchmode due to failure`, an exception stack. Old Unity versions returned exit 0 after "Scripts have compiler errors"; treat the markers as truth and the exit code as a hint.
- Do not pass `-quit` with `-runTests` (the Editor quits before the tests run) or with any method that starts asynchronous work (UPM `Client.Add`, async imports): let the method call `EditorApplication.Exit(code)` when done.
- Useful flags (Unity 6 reference): `-nographics`, `-quitTimeout <s>`, `-accept-apiupdate`, `-ignorecompilererrors`, `-disable-assembly-updater`, `-noUpm`, `-silent-crashes`, `-stackTraceLogType Full`, `-timestamps`, `-job-worker-count N`, `-buildTarget <t>`, `-activeBuildProfile <path>`, `-build <path>` (Unity 6 build profiles), `-importPackage`, `-exportPackage`, `-createProject`, `-rebuildLibrary`, licensing `-username/-password/-serial`, `-returnlicense`, `-manualLicenseFile`.
- The first batchmode run after closing the Editor re-imports the Library and can take minutes; "Unable to upload symbols" in a build log is harmless.

Tests from the command line (Unity Test Framework 1.x/2.x):

```
Unity.exe -batchmode -projectPath "<project>" -runTests -testPlatform EditMode|PlayMode|StandaloneWindows64 -testResults "<project>\Logs\tests.xml" [-testFilter "Name;Other;!Skip"] [-testCategory "Fast"] [-runSynchronously] [-forgetProjectPath] -logFile "<log>"
```

Parse `<test-run total= passed= failed= skipped=>` in the XML; a PlayMode run on a Standalone target builds a player first. `-runSynchronously` is EditMode only.

## Step 4: Unity Hub headless CLI (deprecated fallback)

Hub 3.18 marks it deprecated; it still runs. From a Claude Code or VS Code shell it fails with `Cannot find module '--headless'` because those hosts export `ELECTRON_RUN_AS_NODE=1`, which makes any Electron app run as plain Node: clear the variable first.

```
env -u ELECTRON_RUN_AS_NODE "C:\Program Files\Unity Hub\Unity Hub.exe" -- --headless editors --installed
"Unity Hub.exe" -- --headless install --version 6000.5.8f1 --changeset <hash> --module windows-il2cpp
"Unity Hub.exe" -- --headless install-path --get
```

Output is on stdout after some harmless GPU cache errors; `--json` on `editors`. Hub's log is `%APPDATA%\UnityHub\logs\info-log.json`. Prefer `unity editors` / `unity install` from unity-agent-cli whenever that binary is available.

## Step 5: prove it, then report

Quote the driver's JSON fields or the log lines that decide the outcome (the results XML path with total/failed, or the first `error CS` line with file and line number). "Build succeeded" from dotnet is evidence for the compile check only; say what it does not cover.

## Output

Two lines: the command that ran and the evidence (JSON `ok` plus the deciding numbers or the first error), then the next step if the run failed.

## While working: capture learnings

If the user corrects you, the same error happens twice, a workaround is found, or an environment fact is discovered, write it to `LEARNINGS.md` now (format in MAINTENANCE.md; check existing entries first: add, update, retire, or nothing). If a learning proves a claim above wrong, fix it here, log it in `CHANGELOG.md`, and set `contradiction` in `evergreen.json`.

## Maintenance

This skill is evergreen (topic: Unity batchmode, Test Framework CLI, offline compile checks, logs, Hub CLI; tier `moderate`, currently every 30d, next due 2026-10-06). Files: `evergreen.json` (state), [RESEARCH.md](RESEARCH.md) (findings and search plan), [CHANGELOG.md](CHANGELOG.md) (every change, with reasons), [LEARNINGS.md](LEARNINGS.md) (lessons), [TESTS.md](TESTS.md) and `evals/evals.json` (the cases that prove it and the runs). Protocol: MAINTENANCE.md (pointer to the installed evergreen plugin). Refresh with `evergreen-refresh`; test with `evergreen-test`; fix a failure with `evergreen-tune`; audit with `evergreen-audit`. Sibling skills in this suite: unity-agent-cli, unity-agent-headless, unity-agent-mcp, unity-agent-workflow, unity-agent-packages.
