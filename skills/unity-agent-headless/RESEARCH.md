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
- (resolved 2026-10-11) UTF is a core package fixed to the Editor version in Unity 6 (1.9 on 6.7); the 2.0 line was abandoned in 2022 (R-20261011-1).
- Does `unity_headless.ps1 -Action compile` need a branch for 6.7 MSBuild-mode projects (build the `.slnx`)? Exit code 0 on compile errors in Unity 6 is still unconfirmed.
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

### R-20261029-1 · 2026-10-29 · Practice: behavioural oracles for agent changes (from other engines)
- Summary: Three maker reports (2026-10-24 to 10-29) gate agent changes on behaviour, not on a green build. A solo UE5 dev with 120k lines of agent-written C++ runs four scripts (build, headless test that exits 1 on failure, run with launch flags that start a match, quit after N seconds and screenshot, package audit), uses fast-forward runs (normal against 64x) with a per-tick simulation hash for determinism, keeps a fast and a full test mode, has the agent edit exact lines instead of rewriting files, and batches edits before one test pass; editor plus render ran out of memory during packaging. An agent refactor of the 300k-line Street Fighter III decomp hashed rollback state every frame of a replay trace and discarded any attempt that changed it (2,903 commits, no regressions). A Claude Code port of a 1984 Z80 game diffed memory and screen against the original in a headless emulator. Unity equivalent, untested here: a batchmode `-executeMethod` entry that loads a scene, replays recorded inputs on a fixed timestep and prints a hash of the simulation state per tick, compared against a stored trace.
- Track: practice
- Sources: https://www.reddit.com/r/unrealengine/comments/1xf5o71/working_on_about_120k_lines_of_ue5_c_with_an_ai/, https://www.reddit.com/r/gamedev/comments/1xiepyg/an_agent_refactored_the_whole_of_street_fighter/, https://www.reddit.com/r/ClaudeGameDev/comments/1xegf6v/claude_code_rebuilt_a_1984_amstrad_cpc_game_from/
- Magnitude: 0.1 (practice note; SKILL unchanged until tried on a Unity project)
- Applied: none

 · 2026-10-11 · Subject and testing: 6.7 MSBuild compilation, UTF is a core package, Unity 7 batchmode fixes, MSB3277
- Summary: Unity 6.7 adds experimental MSBuild compilation (Editor setting or `-enable-msbuild`): authoritative `Main.EntryPoint.csproj`, `{project}.slnx`, `Assets/**/*.gen.csproj` and a `global.json` forcing SDK 8.0.0 with `rollForward latestMinor`; direct `dotnet build` is documented; targets `netstandard2.1` or `net10.0` (`enablelastdotnet.config`); NuGet under a policy (MSBU0006, MSBU0007). Unity 7 positions MSBuild as "compiling outside the Editor" for agents. The Test Framework is a core package fixed to the Editor version: 1.9.0 (2026-08-14) ships with 6.7 (Player runs with `-automated` no longer restore the graphics API); 1.8.0 fixed `-testSettingsFile` ignored in EditMode; the registry's `latest` tag is frozen at 1.4.6 and 2.0 stopped at 2.0.1-exp.2 (2022), so "UTF 1.7 or 2.0" was wrong. Unity 7.0.0a7 fixes batchmode runs that seemed to hang up to 10 minutes and sequential `-activeBuildProfile` builds; on Linux `-nographics` without `-batchmode` exits 1; every asset reimports on first open in Unity 7. The 6000.6 command-line page adds `-upmLogFile`, `-upmPack`, `-organization-id` and import-worker flags, and still documents only exit code 1. Testing: `dotnet build` with an SDK above 10 warns MSB3277 for System.Numerics.Vectors (Unity issue 20533), harmless. Tooling: GameCI unity-builder v6.0.0 wraps `game-ci/cli`. Practice: nothing new.
- Track: subject, testing, tooling
- Sources: https://docs.unity.com/en-us/engine/6000.7/manual/programming-environment/script-compilation/msbuild/unity.md, https://packages.unity.com/com.unity.test-framework, https://docs.unity3d.com/Packages/com.unity.test-framework@1.9/changelog/CHANGELOG.html, https://unity.com/releases/editor/alpha/7000.0.0a7, https://docs.unity3d.com/6000.6/Documentation/Manual/EditorCommandLineArguments.html, https://issuetracker.unity.com/issues/20533/msb3277-conflicts-between-different-versions-of-systemnumericsvectors-when-using-dotnet-110, https://github.com/game-ci/unity-builder/releases
- Magnitude: 0.45 (the compile check needs a different target on MSBuild-mode projects)
- Applied: C-20261011-1 (SKILL.md: the csproj paragraph; Tests from the command line)

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
