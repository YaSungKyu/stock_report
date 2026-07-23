# Archive the freshly generated report into THIS separate repo, organized by
# date folder + timestamp filename, then push to public.
# Usage: powershell -File commit_push_reports.ps1 <subdir>   (subdir = gapbet | invest; default gapbet)
# ASCII-only file (no Korean bytes) so Windows PowerShell 5.1 (cp949) parses it safely.
# The Korean si/bun chars in the filename are generated at runtime via code points.
param([string]$Sub = "gapbet")
$ErrorActionPreference = "Continue"
$git  = "C:\Program Files\Git\cmd\git.exe"
$main = "C:\Projects\ai"
$repo = "$main\reports"
$src  = "$main\docs\$Sub"
$logDir = "$repo\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force $logDir | Out-Null }
$glog = "$logDir\git.log"
function Log($m) { Add-Content -Path $glog -Value $m -Encoding UTF8 }
if (-not (Test-Path $src)) { Log "no source dir $src"; exit 0 }
$newest = Get-ChildItem "$src\*.md" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $newest) { Log "no md in $src"; exit 0 }
$d = Get-Date
$day = $d.ToString("yyyy-MM-dd")
$si = [char]0xC2DC; $bun = [char]0xBD84
$stamp = $d.ToString("yyyy-MM-dd_HH") + $si + $d.ToString("mm") + $bun
$destDir = Join-Path $repo (Join-Path $Sub $day)
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force $destDir | Out-Null }
Copy-Item $newest.FullName (Join-Path $destDir "$stamp.md") -Force
& $git -C $repo add -A
& $git -C $repo diff --cached --quiet
if ($LASTEXITCODE -eq 0) { Log "$stamp no report changes"; exit 0 }
& $git -C $repo commit -m "reports: $Sub $stamp" | Out-Null
& $git -C $repo push origin HEAD 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Log "$stamp push OK" } else { Log "$stamp push FAILED - see git.log" }
