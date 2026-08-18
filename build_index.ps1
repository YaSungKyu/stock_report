# Regenerate README indexes so the NEWEST report is listed first and needs no scrolling.
# GitHub and editors sort date folders ascending, which buries today's report at the bottom.
# Root README   : one compact table, latest $Max dates, one column per section. No heading, no blurb.
# Section README: full history for that section, newest first.
# ASCII-only file (no Korean bytes) so Windows PowerShell 5.1 (cp949) parses it safely.
# Korean labels come from the report filenames at runtime.
param([string]$Repo = "C:\Projects\ai\reports", [int]$Max = 5)
$ErrorActionPreference = "Continue"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Esc([string]$s) { [System.Uri]::EscapeDataString($s) }

# Links for one day folder, newest file first. $prefix is prepended to the relative path.
function Get-DayLinks($day, [string]$prefix) {
    $files = Get-ChildItem $day.FullName -Filter *.md -File -ErrorAction SilentlyContinue |
             Sort-Object Name -Descending
    $links = @()
    foreach ($f in $files) {
        $label = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        if ($label -match '^\d{4}-\d{2}-\d{2}_(.+)$') { $label = $Matches[1] }
        $links += "[$label]($prefix$(Esc $day.Name)/$(Esc $f.Name))"
    }
    $links
}

function Get-Days($sectionDir) {
    Get-ChildItem $sectionDir.FullName -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' } |
        Sort-Object Name -Descending
}

$sections = @(Get-ChildItem $Repo -Directory |
              Where-Object { $_.Name -ne "logs" -and $_.Name -notlike ".*" } |
              Sort-Object Name)

# Per section: day name -> rendered links (root-relative), plus the full-history README.
$byDay = @{}
$live  = @()
foreach ($s in $sections) {
    $days = @(Get-Days $s)
    if ($days.Count -eq 0) { continue }
    $live += $s.Name
    $map = @{}
    $sec = @()
    foreach ($d in $days) {
        $map[$d.Name] = (Get-DayLinks $d "$(Esc $s.Name)/") -join " "
        $line = (Get-DayLinks $d "") -join " "
        if ($line) { $sec += "**$($d.Name)** $line" + "  " }
    }
    $byDay[$s.Name] = $map
    [System.IO.File]::WriteAllText((Join-Path $s.FullName "README.md"), (($sec -join "`n") + "`n"), $utf8)
}

# Root: one row per date, one column per section, newest first.
$allDays = @($byDay.Values | ForEach-Object { $_.Keys } | Sort-Object -Unique -Descending)
$root = @()
$root += "| | " + ($live -join " | ") + " |"
$root += "|---|" + (($live | ForEach-Object { "---|" }) -join "")
foreach ($day in ($allDays | Select-Object -First $Max)) {
    $cells = foreach ($name in $live) {
        $v = $byDay[$name][$day]
        if ($v) { $v } else { "-" }
    }
    $root += "| **$day** | " + ($cells -join " | ") + " |"
}
$root += ""
$root += "older: " + (($live | ForEach-Object { "[$_]($(Esc $_)/README.md)" }) -join " . ")
$root += ""
[System.IO.File]::WriteAllText((Join-Path $Repo "README.md"), ($root -join "`n"), $utf8)
