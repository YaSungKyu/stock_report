# Regenerate README indexes so the NEWEST report is listed first and needs no scrolling.
# GitHub and editors sort date folders ascending, which buries today's report at the bottom.
# Root README   : latest $Max dates, one line each, no heading and no table (tables get
#                 squeezed on phones; a plain list wraps instead).
# Section README: full history for that section, newest first.
# ASCII-only file (no Korean bytes) so Windows PowerShell 5.1 (cp949) parses it safely.
# Korean labels come from the report filenames at runtime.
param([string]$Repo = "C:\Projects\ai\reports", [int]$Max = 5)
$ErrorActionPreference = "Continue"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Esc([string]$s) { [System.Uri]::EscapeDataString($s) }

# "gapbet_review" -> "review": the phone screen has no room for the redundant prefix.
function Get-ShortName([string]$s) {
    if ($s -like "gapbet_*") { $s.Substring(7) } else { $s }
}

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

# Root: sections kept apart, one line per date, newest first. The section heading links
# to that section's full history, so no separate "older" line is needed.
$root = @()
foreach ($name in $live) {
    $root += "#### [$(Get-ShortName $name)]($(Esc $name)/README.md)"
    foreach ($day in ($byDay[$name].Keys | Sort-Object -Descending | Select-Object -First $Max)) {
        $root += "- **$day** " + $byDay[$name][$day]
    }
    $root += ""
}
$root += ""
[System.IO.File]::WriteAllText((Join-Path $Repo "README.md"), ($root -join "`n"), $utf8)
