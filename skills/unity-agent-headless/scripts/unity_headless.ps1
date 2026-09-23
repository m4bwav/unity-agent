<#
.SYNOPSIS
Headless Unity driver for agents: compile check, Test Framework run, or a
batchmode -executeMethod pass. Prints one JSON summary parsed from the evidence.

.DESCRIPTION
-Action compile : dotnet build of the Unity-generated *.csproj at the project
                  root (works while the Editor is open; ~seconds). Uses the
                  system .NET SDK when one is installed, else the SDK bundled
                  inside the project's pinned Unity editor (Data\DotNetSdk).
-Action tests   : Unity.exe -batchmode -runTests (Editor must be closed).
                  Parses the NUnit XML for total/passed/failed/skipped.
-Action method  : Unity.exe -batchmode -quit -executeMethod <Method>.
                  Parses the log for "error CS", "Scripts have compiler
                  errors", and "Exiting batchmode successfully".

Refuses batchmode while a running Editor owns Temp\UnityLockfile; removes a
stale lockfile that no process owns. Logs go to <project>\Logs\agent-*.log.

Keep this file pure ASCII (Windows PowerShell 5.1 mis-parses non-ASCII in
BOM-less scripts).

.EXAMPLE
unity_headless.ps1 -Project "C:\Proj" -Action compile
unity_headless.ps1 -Project "C:\Proj" -Action tests -TestPlatform EditMode -TestFilter "MyTests"
unity_headless.ps1 -Project "C:\Proj" -Action method -Method BuildScript.BuildWindows
#>
param(
    [string]$Project = (Get-Location).Path,
    [ValidateSet('compile', 'tests', 'method')]
    [string]$Action = 'compile',
    [string]$Method,
    [ValidateSet('EditMode', 'PlayMode', 'StandaloneWindows64')]
    [string]$TestPlatform = 'EditMode',
    [string]$TestFilter,
    [string]$TestCategory,
    # Override the editor executable (otherwise resolved from ProjectVersion.txt).
    [string]$UnityPath,
    # Override the dotnet executable used for -Action compile.
    [string]$DotnetPath,
    # csproj files to build for -Action compile (relative to the project root).
    [string[]]$Csproj = @('Assembly-CSharp.csproj', 'Assembly-CSharp-Editor.csproj'),
    [int]$TimeoutSec = 1800,
    [switch]$NoGraphics
)

$ErrorActionPreference = 'Stop'
$Project = (Resolve-Path $Project).Path.TrimEnd('\', '/')
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logDir = Join-Path $Project 'Logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force $logDir | Out-Null }

$out = [ordered]@{
    action = $Action; project = $Project; ok = $false; exitCode = $null
    editor = $null; log = $null; errorsCS = 0; firstError = $null
    compilerErrors = $false; exitedCleanly = $false; tests = $null; notes = @()
}

function Resolve-Editor {
    if ($UnityPath) { return $UnityPath }
    $pv = Join-Path $Project 'ProjectSettings\ProjectVersion.txt'
    if (-not (Test-Path $pv)) { throw "not a Unity project (no $pv)" }
    $version = ((Select-String -Path $pv -Pattern 'm_EditorVersion: (.+)').Matches[0].Groups[1].Value).Trim()
    $candidates = @("C:\Program Files\Unity\Hub\Editor\$version\Editor\Unity.exe")
    $cli = Get-Command unity -ErrorAction SilentlyContinue
    $cliPath = if ($cli) { $cli.Source } elseif (Test-Path "$env:LOCALAPPDATA\Unity\bin\unity.exe") { "$env:LOCALAPPDATA\Unity\bin\unity.exe" } else { $null }
    if ($cliPath) {
        try {
            $j = & $cliPath editors path $version --format json --no-banner 2>$null | ConvertFrom-Json
            if ($j.success -and $j.data.path) { $candidates += (Join-Path $j.data.path 'Editor\Unity.exe') }
        } catch {}
    }
    $hubJson = Join-Path $env:APPDATA 'UnityHub\editors-v2.json'
    if (Test-Path $hubJson) {
        $raw = Get-Content $hubJson -Raw
        $m = [regex]::Match($raw, '"([A-Za-z]:[^"]*' + [regex]::Escape($version) + '[^"]*Unity\.exe)"')
        if ($m.Success) { $candidates += ($m.Groups[1].Value -replace '\\\\', '\') }
    }
    foreach ($c in $candidates) { if (Test-Path $c) { return $c } }
    throw "Unity $version not found (tried: $($candidates -join '; ')). Install it (unity install $version) or pass -UnityPath."
}

function Assert-NotLocked {
    $lock = Join-Path $Project 'Temp\UnityLockfile'
    if (-not (Test-Path $lock)) { return }
    $esc = [regex]::Escape($Project)
    $owners = @(Get-CimInstance Win32_Process -Filter "Name='Unity.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match $esc -and $_.CommandLine -notmatch 'AssetImportWorker' })
    if ($owners.Count -gt 0) {
        throw "The Unity Editor has this project open (PID $($owners[0].ProcessId)); batchmode needs the project lock. Close it, or use unity-agent-cli live commands instead."
    }
    Remove-Item $lock -Force -Confirm:$false
    $script:out.notes += 'removed stale Temp\UnityLockfile (no editor process owns this project)'
}

function Read-UnityLog([string]$path) {
    if (-not (Test-Path $path)) { $script:out.notes += "log not found: $path"; return }
    $lines = Get-Content $path
    $cs = @($lines | Where-Object { $_ -match 'error CS\d{4}' })
    $script:out.errorsCS = $cs.Count
    if ($cs.Count -gt 0) { $script:out.firstError = $cs[0].Trim() }
    $script:out.compilerErrors = [bool]($lines | Where-Object { $_ -match 'Scripts have compiler errors' })
    $script:out.exitedCleanly = [bool]($lines | Where-Object { $_ -match 'Exiting batchmode successfully' })
    $abort = $lines | Where-Object { $_ -match 'Aborting batchmode due to failure' } | Select-Object -First 1
    if ($abort) { $script:out.notes += $abort.Trim() }
}

function Invoke-Unity([string[]]$unityArgs, [string]$log) {
    $exe = Resolve-Editor
    $script:out.editor = $exe
    $script:out.log = $log
    Assert-NotLocked
    $argLine = ($unityArgs | ForEach-Object { if ($_ -match '\s') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $p = Start-Process -FilePath $exe -ArgumentList $argLine -PassThru -NoNewWindow
    if (-not $p.WaitForExit($TimeoutSec * 1000)) {
        try { $p.Kill() } catch {}
        $script:out.notes += "killed after ${TimeoutSec}s timeout"
        $script:out.exitCode = -1
    } else {
        $script:out.exitCode = $p.ExitCode
    }
    Read-UnityLog $log
}

try {
switch ($Action) {
    'compile' {
        $dn = $DotnetPath
        if (-not $dn) {
            $sys = Get-Command dotnet -ErrorAction SilentlyContinue
            if ($sys -and @(& $sys.Source --list-sdks 2>$null).Count -gt 0) { $dn = $sys.Source }
        }
        if (-not $dn) {
            $exe = Resolve-Editor
            $bundled = Join-Path (Split-Path $exe -Parent) 'Data\DotNetSdk\dotnet.exe'
            if (Test-Path $bundled) { $dn = $bundled; $out.notes += 'no system .NET SDK; using the SDK bundled with the Unity editor' }
        }
        if (-not $dn) { throw 'no dotnet SDK found (system or Unity-bundled)' }
        $out.editor = $dn
        $log = Join-Path $logDir "agent-compile-$stamp.log"
        $out.log = $log
        $present = @($Csproj | ForEach-Object { Join-Path $Project $_ } | Where-Object { Test-Path $_ })
        if ($present.Count -eq 0) {
            throw "no csproj found at the project root ($($Csproj -join ', ')). Open the project once with an IDE configured (Preferences > External Tools > Generate .csproj files), or run -Action method with the Editor closed."
        }
        $all = ''
        $worst = 0
        foreach ($cp in $present) {
            $text = & $dn build $cp --nologo -v minimal 2>&1 | Out-String
            $all += "=== $cp`n$text`n"
            if ($LASTEXITCODE -ne 0) { $worst = $LASTEXITCODE }
        }
        Set-Content -Path $log -Value $all -Encoding ASCII
        $out.exitCode = $worst
        $cs = @($all -split "`n" | Where-Object { $_ -match 'error CS\d{4}' })
        $out.errorsCS = $cs.Count
        if ($cs.Count -gt 0) { $out.firstError = $cs[0].Trim() }
        $out.compilerErrors = ($cs.Count -gt 0)
        $out.ok = ($worst -eq 0 -and $cs.Count -eq 0)
        $out.notes += "built: $($present -join ', ')"
        $out.notes += 'compile check only: csproj is a snapshot of the last Editor sync; scenes/assets/serialization not covered'
    }
    'tests' {
        $xml = Join-Path $logDir "agent-tests-$TestPlatform-$stamp.xml"
        $log = Join-Path $logDir "agent-tests-$TestPlatform-$stamp.log"
        $a = @('-batchmode', '-projectPath', $Project, '-runTests', '-testPlatform', $TestPlatform, '-testResults', $xml, '-logFile', $log)
        if ($NoGraphics) { $a += '-nographics' }
        if ($TestFilter) { $a += @('-testFilter', $TestFilter) }
        if ($TestCategory) { $a += @('-testCategory', $TestCategory) }
        Invoke-Unity $a $log
        if (Test-Path $xml) {
            [xml]$doc = Get-Content $xml
            $r = $doc.'test-run'
            $out.tests = [ordered]@{
                xml = $xml; total = [int]$r.total; passed = [int]$r.passed
                failed = [int]$r.failed; skipped = [int]$r.skipped; result = $r.result
            }
            $out.ok = ([int]$r.failed -eq 0 -and [int]$r.total -gt 0 -and $out.errorsCS -eq 0)
            if ([int]$r.total -eq 0) { $out.notes += 'zero tests ran: check the filter/platform' }
        } else {
            $out.notes += "no results XML at $xml (Editor did not reach the test run; read the log)"
        }
    }
    'method' {
        if (-not $Method) { throw '-Method Class.Method is required for -Action method' }
        $log = Join-Path $logDir "agent-method-$stamp.log"
        $a = @('-batchmode', '-quit', '-projectPath', $Project, '-executeMethod', $Method, '-logFile', $log)
        if ($NoGraphics) { $a += '-nographics' }
        Invoke-Unity $a $log
        $out.ok = ($out.exitCode -eq 0 -and $out.errorsCS -eq 0 -and -not $out.compilerErrors -and $out.exitedCleanly)
    }
}

} catch {
    # Any refusal or setup failure still yields one JSON object and exit 1,
    # so a caller never has to parse a stack trace.
    $out.notes += "error: $($_.Exception.Message)"
    $out.ok = $false
}

$out | ConvertTo-Json -Depth 5
if (-not $out.ok) { exit 1 }
