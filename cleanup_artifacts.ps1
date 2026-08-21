# Bounds every place a gapbet run leaves files behind. Called at the START of each scheduled
# run, so the most recent run's artifacts always survive for post-mortem while older ones never
# pile up. Lifecycle lives here, in the wrapper -- not in the skill prose, which depends on the
# model remembering to clean up and it does not.
#
# Paths are literal and each one is scoped to a single known directory. No wildcards that could
# walk upward. Nothing here touches tracked source or docs/.
param([switch]$WhatIfOnly)

$Main = 'C:\Projects\ai'
$removed = 0; $bytes = 0

function Prune($Path, $Days, $Label) {
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $cut = (Get-Date).AddDays(-$Days)
    $old = @(Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue |
             Where-Object { $_.LastWriteTime -lt $cut })
    if ($old.Count -eq 0) { return }
    $sz = ($old | Measure-Object Length -Sum).Sum
    Write-Host ("  {0}: {1} files / {2:N0} KB older than {3}d" -f $Label, $old.Count, ($sz/1KB), $Days)
    if (-not $WhatIfOnly) { $old | Remove-Item -Force -ErrorAction SilentlyContinue }
    $script:removed += $old.Count; $script:bytes += $sz
}

# Run scratch: purged whole, not pruned. Keeping one run's worth is the point -- this runs
# before the scan, so the previous run's files are what get cleared.
$scratch = Join-Path $env:TEMP 'gapbet'
if (Test-Path -LiteralPath $scratch) {
    $f = @(Get-ChildItem -LiteralPath $scratch -Recurse -File -ErrorAction SilentlyContinue)
    if ($f.Count) {
        $sz = ($f | Measure-Object Length -Sum).Sum
        Write-Host ("  scratch: {0} files / {1:N0} KB (previous run)" -f $f.Count, ($sz/1KB))
        $script:removed += $f.Count; $script:bytes += $sz
    }
    if (-not $WhatIfOnly) { Remove-Item -LiteralPath $scratch -Recurse -Force -ErrorAction SilentlyContinue }
}
if (-not $WhatIfOnly) { New-Item -ItemType Directory -Force -Path $scratch | Out-Null }

Prune (Join-Path $Main '.playwright-mcp')            3  'playwright'   # browser snapshots, no value after the run
Prune (Join-Path $Main 'reports\logs')              30  'run logs'     # review reads recent ones
Prune (Join-Path $Main '.claude\skills\gapbet\logs') 30 'skill logs'

# Stray run artifacts in the skill dir. The skill is told to write to %TEMP%; this catches it
# when it forgets. docs/ and the tracked sources are untouched.
$skill = Join-Path $Main '.claude\skills\gapbet'
$stray = @(Get-ChildItem -LiteralPath $skill -File -Filter *.json -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -ne 'kis.json' })
if ($stray.Count) {
    Write-Host ("  stray json in skill dir: {0} -- skill wrote outside %TEMP%" -f ($stray.Name -join ', '))
    if (-not $WhatIfOnly) { $stray | Remove-Item -Force -ErrorAction SilentlyContinue }
    $script:removed += $stray.Count
}
foreach ($pc in @('.claude\skills\gapbet\__pycache__', '.claude\skills\gapbet_review\__pycache__')) {
    $p = Join-Path $Main $pc
    if ((Test-Path -LiteralPath $p) -and -not $WhatIfOnly) {
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
    }
}
if ($removed -eq 0) { Write-Host '  nothing to clean' }
else { Write-Host ("cleanup: {0} files / {1:N0} KB" -f $removed, ($bytes/1KB)) }
