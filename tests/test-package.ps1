$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$controls = Join-Path $repo 'controls_ow2s0smsguard.txt'
$module = Join-Path $repo 'FHEM\00_OW2S0SMSGUARD.pm'
$dashboard = Join-Path $repo 'examples\onewire_sensordiagnose.pl'

if (-not (Test-Path -LiteralPath $controls)) { throw 'controls file missing' }
if (-not (Test-Path -LiteralPath $module)) { throw 'module missing' }
if (-not (Test-Path -LiteralPath $dashboard)) { throw 'dashboard example missing' }

$lines = @(Get-Content -LiteralPath $controls | Where-Object { $_ -match '^UPD ' })
if ($lines.Count -ne 1) { throw "expected exactly one UPD entry, got $($lines.Count)" }
if ($lines[0] -notmatch ' FHEM/00_OW2S0SMSGUARD\.pm$') { throw 'controls file distributes an unexpected path' }

$expectedSize = (Get-Item -LiteralPath $module).Length
$declaredSize = [int64](($lines[0] -split '\s+')[2])
if ($expectedSize -ne $declaredSize) { throw "size mismatch: controls=$declaredSize file=$expectedSize" }

$sumLine = Get-Content -LiteralPath (Join-Path $repo 'SHA256SUMS.txt') | Where-Object { $_ -match 'FHEM/00_OW2S0SMSGUARD\.pm$' }
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $module).Hash.ToLowerInvariant()
if ($sumLine -notmatch "^$actualHash\s+") { throw 'module SHA256 mismatch' }

Write-Output 'package test OK: one module file, matching size and SHA256; dashboard is separate'
