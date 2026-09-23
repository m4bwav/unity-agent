# Research: unity-agent-headless

Findings that back [SKILL.md](SKILL.md). Changes they caused are logged in [CHANGELOG.md](CHANGELOG.md); procedural lessons live in [LEARNINGS.md](LEARNINGS.md); test runs in [TESTS.md](TESTS.md); schedule and state in `evergreen.json`. Protocol: MAINTENANCE.md.

Topic: Unity Editor batchmode and Test Framework command line, offline C# compile checks with dotnet against Unity-generated csproj and the Unity-bundled .NET SDK, Unity 6 log locations and exit-code traps, Unity Hub headless CLI. Tier `moderate`. Last refresh 2026-09-06; next due 2026-10-06.

## Current understanding

- The Unity 6000.5 command-line reference lists every flag the skill names; Unity 6 additions are `-activeBuildProfile <path>` and `-build <path>`. Only exit code 1 is documented for batchmode failures; older versions returned 0 after "Scripts have compiler errors", and whether Unity 6 fixed that is unconfirmed, so the log markers decide.
- Unity 6 writes the Editor log per project at `<project>/Logs/Editor.log`; the global `%LOCALAPPDATA%\Unity\Editor\Editor.log` only with `-useGlobalLog`. UPM log `<project>/Logs/upm.log`.
- Unity Test Framework CLI: `-runTests -testPlatform EditMode|PlayMode|<BuildTarget> -testResults <xml> -testFilter -testCategory -testNames -assemblyNames -forgetProjectPath -runSynchronously (EditMode only)`. UTF 2.0 resolves a relative `-testResults` against the project dir and prints a settings summary; UTF 1.7 fixed a `WaitForEndOfFrame` batchmode hang. Never pass `-quit` with `-runTests`.
- Offline compile check: Unity's generated `Assembly-CSharp.csproj` is SDK-style (`Sdk="Microsoft.NET.Sdk"`, netstandard2.1, absolute HintPaths into the Editor install). `dotnet build` on it succeeded in about 3 s while the Editor was open, using the SDK Unity bundles at `Editor\Data\DotNetSdk\dotnet.exe` (8.0.318 in 6000.5.x). That bundled SDK cannot target net9.0 (NETSDK1045), so a net9.0 test project still needs a system SDK.
- Editor lock: a second Editor or batchmode on an open project fails ("Multiple Unity instances cannot open the same project"); `Temp/UnityLockfile` plus a `Unity.exe` process whose command line names the project is the reliable check (asset import workers also carry the path and `-batchMode`, so exclude `AssetImportWorker`).
- Hub headless CLI (`"Unity Hub.exe" -- --headless editors|install|install-path|install-modules|help`, `--json`) is deprecated from Hub 3.18 but works. From Claude Code or VS Code shells it fails with `Cannot find module '--headless'` unless `ELECTRON_RUN_AS_NODE` is cleared (observed 2026-09-06). Hub log: `%APPDATA%\UnityHub\logs\info-log.json`.
- Third-party open-Editor bridges (youngwoocho02/unity-cli, yucchiy/UniCli, akiojin/unity-cli, RageAgainstThePixel/unity-cli) exist but the official CLI (unity-agent-cli) supersedes them for new work. GameCI unity-builder v5/v6 wraps the same batchmode flags for CI.

## Open questions

- Is the exit-0-on-compile-error batchmode bug fixed in 6000.5? (issue tracker page lost in the migration.)
- Which UTF version ships with 6000.5 by default (1.7 vs 2.0) and does `-testResults` relative-path behaviour differ.
- Does `-nographics` change anything for UI Toolkit tests in PlayMode on Windows.

## Search plan

Four tracks; every refresh runs at least one query on each (scope each to the period since the last refresh; add the year). Protocol §4 explains the tracks and how tooling findings are judged.

Subject (the goal and the latest thinking on reaching it):

- `docs.unity3d.com/<version>/Documentation/Manual/EditorCommandLineArguments.html` (diff against the previous version); `docs.unity3d.com/<version>/Documentation/Manual/log-files.html`
- `docs.unity3d.com/Packages/com.unity.test-framework@<latest>/manual/reference-command-line.html` and its changelog
- `unity batchmode "Scripts have compiler errors" exit code <year>`

Tooling (skills, plugins, MCP servers, scripts, knowledge graphs built for this subject):

- `path:SKILL.md unity batchmode OR "-executeMethod" OR "-runTests"` on GitHub code search; `npx skills find unity test`; skills.sh
- `https://registry.modelcontextprotocol.io/v0/servers?search=unity`; game-ci/unity-builder releases; `unity-cli site:github.com stars:>100 <year>`

Practice (how others use AI agents on this goal, and everything in between):

- `"dotnet build" "Assembly-CSharp.csproj" unity agent OR "claude code" <year>`; gamedev.center; discussions.unity.com "humble object" agent
- hn.algolia.com `unity headless agent` sorted by date

Testing (how the job is verified and what checkers exist):

- `unity test framework nunit xml parse ci <year>`; `"-testResults" "test-run" total failed`
- `unity batchmode timeout hang "-quitTimeout" <year>`

Best sources (primary first): docs.unity3d.com Manual and package pages (fetch fine), the Editor's own `Logs/` output, github.com/game-ci. Noisy: docs.unity.com (JS-rendered), Medium (403), issuetracker.unity3d.com links (dead after migration).

## Findings log

Newest first. One entry per material finding; a quiet refresh gets one entry saying so. `Track` is subject, tooling, practice, or testing.

### R-20260906-3 · 2026-09-06 · Local verification: compile check, lock refusal, Hub CLI
- Summary: `unity_headless.ps1 -Action compile` built `Assembly-CSharp.csproj` and `Assembly-CSharp-Editor.csproj` (0 errors, ~3 s) with the Unity-bundled SDK while the Editor held the project; `-Action method` refused with the PID of the owning Editor; the Hub headless `editors --installed` worked only after `env -u ELECTRON_RUN_AS_NODE`. The repo's net9.0 test project failed on the bundled SDK with NETSDK1045.
- Track: testing
- Sources: local runs 2026-09-06 on the development machine (a Unity 6 game project, Unity 6000.5.0f1)
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-2 · 2026-09-06 · Unity 6000.5 command-line and log references; UTF CLI
- Summary: Flag list verified on the 6000.5 Manual; per-project `Logs/Editor.log` in Unity 6; UTF 2.0 changelog (relative `-testResults`, batchmode summary) and 1.7 (batchmode hang fix). Exit code 0 on compile errors was a real bug in 2019-2022; fix status unknown.
- Track: subject
- Sources: https://docs.unity3d.com/6000.5/Documentation/Manual/EditorCommandLineArguments.html, https://docs.unity3d.com/6000.5/Documentation/Manual/log-files.html, https://docs.unity3d.com/Packages/com.unity.test-framework@2.0/manual/reference-command-line.html, https://docs.unity3d.com/Packages/com.unity.test-framework@2.0/changelog/CHANGELOG.html
- Magnitude: n/a (initial)
- Applied: C-20260906-1

### R-20260906-1 · 2026-09-06 · Hub CLI deprecated; third-party CLIs; dotnet-against-Unity-DLLs practice
- Summary: Hub CLI deprecated from Hub 3.18 (docs.unity.com snippet; docs.unity.cn has the command list). Community CLIs (Go/Rust/named-pipe bridges, 100-300 stars) predate the official one. gamedev.center (2026-03) documents linking `Assets/**/*.cs` into a .NET test project against `UnityEngine.CoreModule.dll`; matches the stub approach used in the game project this suite was built on.
- Track: tooling
- Sources: https://docs.unity.com/en-us/hub/use-hub-cli, https://docs.unity.cn/hub/manual/HubCLI.html, https://github.com/youngwoocho02/unity-cli, https://github.com/yucchiy/UniCli, https://github.com/game-ci/unity-builder/releases, https://gamedev.center/run-unity-tests-faster-dotnet/
- Magnitude: n/a (initial)
- Applied: C-20260906-1
