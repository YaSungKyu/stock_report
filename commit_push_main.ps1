# Commit & push gapbet skill/tuning edits made by a scheduled run to the MAIN repo.
# Scoped to the gapbet skill dirs only (never -A), so unrelated working-tree changes and
# gitignored secrets (kis.json etc.) are excluded. ASCII only (cp949-safe).
$ErrorActionPreference = "Continue"
$git  = "C:\Program Files\Git\cmd\git.exe"
$main = "C:\Projects\ai"
$logDir = "$main\reports\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force $logDir | Out-Null }
$glog = "$logDir\git.log"
function Log($m) { Add-Content -Path $glog -Value $m -Encoding UTF8 }
$paths = @(".claude/skills/gapbet", ".claude/skills/gapbet_review")
& $git -C $main add -- $paths
& $git -C $main diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Log "$((Get-Date).ToString('yyyy-MM-dd_HHmm')) main: no gapbet changes"; exit 0 }
$stamp = (Get-Date).ToString("yyyy-MM-dd_HHmm")
& $git -C $main commit -m "gapbet: scheduled auto-update $stamp" | Out-Null
& $git -C $main push origin HEAD 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Log "$stamp main push OK" } else { Log "$stamp main push FAILED - see git.log" }
