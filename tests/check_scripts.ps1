<#
.SYNOPSIS
Parses both PowerShell scripts and runs them against an empty folder on a machine that may have no
Unity at all. Each script must print exactly one JSON object with its documented keys; the headless
driver must report ok = false for a folder that is not a Unity project. Exits 0 when all checks pass.
Run from the repository root with either Windows PowerShell 5.1 or PowerShell 7.
#>
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$root = Split-Path -Parent $PSScriptRoot
$probe = Join-Path $root 'skills/unity-agent-cli/scripts/unity_probe.ps1'
$headless = Join-Path $root 'skills/unity-agent-headless/scripts/unity_headless.ps1'
$failed = @()

foreach ($f in @($probe, $headless)) {
    $tokens = $null; $errs = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($f, [ref]$tokens, [ref]$errs)
    if ($errs -and $errs.Count -gt 0) { $failed += "parse: $(Split-Path -Leaf $f): $($errs[0].Message)" }
}

$empty = Join-Path ([System.IO.Path]::GetTempPath()) ('ua-empty-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Force $empty | Out-Null
$shell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }

function Invoke-Json($script, $argList) {
    $out = & $shell -NoProfile -ExecutionPolicy Bypass -File $script @argList 2>$null | Out-String
    try { return ($out | ConvertFrom-Json) } catch { return $null }
}

$p = Invoke-Json $probe @('-Project', $empty)
if ($null -eq $p) { $failed += 'probe: output is not one JSON object' }
else {
    foreach ($k in 'probedAt', 'project', 'cli', 'editors', 'running', 'pipeline', 'lockfile', 'dotnet') {
        if (-not ($p.PSObject.Properties.Name -contains $k)) { $failed += "probe: JSON lacks '$k'" }
    }
}

$h = Invoke-Json $headless @('-Project', $empty, '-Action', 'compile')
if ($null -eq $h) { $failed += 'headless: output is not one JSON object' }
else {
    foreach ($k in 'action', 'project', 'ok', 'notes') {
        if (-not ($h.PSObject.Properties.Name -contains $k)) { $failed += "headless: JSON lacks '$k'" }
    }
    if ($h.ok -ne $false) { $failed += 'headless: an empty folder must report ok = false' }
}

Remove-Item -Recurse -Force $empty
if ($failed.Count -gt 0) { $failed | ForEach-Object { Write-Output "FAIL $_" }; exit 1 }
Write-Output "ok: both scripts parse and print one JSON object ($shell $($PSVersionTable.PSVersion))"
exit 0
