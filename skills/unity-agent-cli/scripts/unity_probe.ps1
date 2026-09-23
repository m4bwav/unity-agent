<#
.SYNOPSIS
One-shot Unity environment probe for agents. Prints a single JSON object.

.DESCRIPTION
Reports: the official Unity CLI (path, version), installed editors (from the
CLI when present, else the Hub's default install folder), running Unity Editor
processes with the project they hold open, whether each open project has the
Pipeline package and a reachable server (from `unity pipeline list`), the
project lockfile, and which .NET SDKs are reachable (system dotnet, then the
SDK bundled with each installed Unity editor). Read-only; never starts Unity.

Keep this file pure ASCII: Windows PowerShell 5.1 reads BOM-less scripts as
ANSI and mis-parses non-ASCII characters.

.EXAMPLE
powershell -NoProfile -File unity_probe.ps1 -Project "C:\path\to\project"
#>
param(
    # Project root to inspect for a lockfile and a Pipeline descriptor.
    # Defaults to the current directory.
    [string]$Project = (Get-Location).Path
)

$ErrorActionPreference = 'Continue'
$result = [ordered]@{
    probedAt = (Get-Date).ToString('s')
    project  = $Project
    cli      = $null
    editors  = @()
    running  = @()
    pipeline = $null
    lockfile = $null
    dotnet   = [ordered]@{ system = $null; unityBundled = @() }
    notes    = @()
}

# --- Unity CLI ---------------------------------------------------------------
$cliPath = $null
$cmd = Get-Command unity -ErrorAction SilentlyContinue
if ($cmd) { $cliPath = $cmd.Source }
elseif (Test-Path "$env:LOCALAPPDATA\Unity\bin\unity.exe") {
    $cliPath = "$env:LOCALAPPDATA\Unity\bin\unity.exe"
    $result.notes += 'unity.exe exists but is not on this shell PATH (restart the terminal); using the full path'
}
if ($cliPath) {
    $ver = (& $cliPath --version 2>$null | Select-Object -First 1)
    $result.cli = [ordered]@{ path = $cliPath; version = "$ver".Trim() }
}

# --- Installed editors -------------------------------------------------------
if ($cliPath) {
    try {
        $j = & $cliPath editors --installed --format json --no-banner 2>$null | ConvertFrom-Json
        if ($j.success) {
            $result.editors = @($j.data | ForEach-Object {
                [ordered]@{ version = $_.version; location = $_.location; modules = $_.modules }
            })
        }
    } catch { $result.notes += "unity editors failed: $($_.Exception.Message)" }
}
if ($result.editors.Count -eq 0) {
    $hubRoot = 'C:\Program Files\Unity\Hub\Editor'
    if (Test-Path $hubRoot) {
        $result.editors = @(Get-ChildItem $hubRoot -Directory | ForEach-Object {
            $exe = Join-Path $_.FullName 'Editor\Unity.exe'
            if (Test-Path $exe) { [ordered]@{ version = $_.Name; location = $exe; modules = $null } }
        })
        $result.notes += 'editors listed from the default Hub folder (no CLI)'
    }
}

# --- Running editors ---------------------------------------------------------
$procs = Get-CimInstance Win32_Process -Filter "Name='Unity.exe'" -ErrorAction SilentlyContinue
foreach ($p in $procs) {
    $cl = "$($p.CommandLine)"
    # Asset import workers carry -batchMode -noUpm -name AssetImportWorker...; skip them.
    if ($cl -match '-name\s+"?AssetImportWorker') { continue }
    $proj = $null
    if ($cl -match '-projectpath\s+"([^"]+)"') { $proj = $Matches[1] }
    elseif ($cl -match '-projectpath\s+(\S+)') { $proj = $Matches[1] }
    $result.running += [ordered]@{
        pid = $p.ProcessId
        exe = $p.ExecutablePath
        projectPath = $proj
        batchmode = [bool]($cl -match '-batchmode')
    }
}

# --- Pipeline package state --------------------------------------------------
if ($cliPath) {
    try {
        $j = & $cliPath pipeline list --format json --no-banner 2>$null | ConvertFrom-Json
        if ($j.success) {
            $result.pipeline = @($j.data.instances | ForEach-Object {
                [ordered]@{
                    projectPath = $_.projectPath; pid = $_.pid; isRunning = $_.isRunning
                    hasPipelinePackage = $_.hasPipelinePackage; pipelineVersion = $_.pipelineVersion
                    reachable = $_.pipelineServer.isReachable; safeMode = $_.safeMode
                }
            })
        }
    } catch { $result.notes += "unity pipeline list failed: $($_.Exception.Message)" }
}
$descriptor = Join-Path $Project 'Library\Pipeline\.unity-pipeline-port'
if (Test-Path $descriptor) {
    try {
        $d = Get-Content $descriptor -Raw | ConvertFrom-Json
        $result.notes += "Pipeline descriptor present: pid $($d.pid), port $($d.port), mode $($d.mode), heartbeat $($d.lastHeartbeat) (token not shown)"
    } catch { $result.notes += 'Pipeline descriptor present but unreadable' }
}

# --- Lockfile ----------------------------------------------------------------
$lock = Join-Path $Project 'Temp\UnityLockfile'
$owner = $result.running | Where-Object { $_.projectPath -and ($_.projectPath.TrimEnd('\','/') -ieq $Project.TrimEnd('\','/')) }
$result.lockfile = [ordered]@{
    present = (Test-Path $lock)
    ownedByRunningEditor = [bool]$owner
    stale = ((Test-Path $lock) -and -not $owner)
}

# --- .NET SDKs ---------------------------------------------------------------
$sys = Get-Command dotnet -ErrorAction SilentlyContinue
if ($sys) {
    $sdks = & $sys.Source --list-sdks 2>$null
    $result.dotnet.system = [ordered]@{ path = $sys.Source; sdks = @($sdks | ForEach-Object { "$_".Trim() }) }
}
foreach ($e in $result.editors) {
    if (-not $e.location) { continue }
    $edDir = Split-Path $e.location -Parent
    $bundled = Join-Path $edDir 'Data\DotNetSdk\dotnet.exe'
    if (Test-Path $bundled) {
        $v = (& $bundled --version 2>$null | Select-Object -First 1)
        $result.dotnet.unityBundled += [ordered]@{ editor = $e.version; path = $bundled; sdk = "$v".Trim() }
    }
}
if (-not $result.dotnet.system -or $result.dotnet.system.sdks.Count -eq 0) {
    $result.notes += 'no system .NET SDK: use a Unity-bundled DotNetSdk\dotnet.exe for dotnet build/test (see unity-agent-headless)'
}

$result | ConvertTo-Json -Depth 6
