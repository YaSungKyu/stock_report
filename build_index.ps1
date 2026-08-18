# Regenerate README indexes so the NEWEST report is listed first.
# GitHub and editors sort date folders ascending; these indexes give the reverse view.
# Writes reports\README.md (all sections) and reports\<sub>\README.md (one section).
# ASCII-only file (no Korean bytes) so Windows PowerShell 5.1 (cp949) parses it safely.
# Korean labels come from the report filenames at runtime.
param([string]$Repo = "C:\Projects\ai\reports", [int]$Max = 5)
$ErrorActionPreference = "Continue"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Esc([string]$s) { [System.Uri]::EscapeDataString($s) }

function Get-DayLine($day, [string]$prefix) {
    $files = Get-ChildItem $day.FullName -Filter *.md -File -ErrorAction SilentlyContinue |
             Sort-Object Name -Descending
    if (-not $files) { return $null }
    $links = @()
    foreach ($f in $files) {
        $label = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
        if ($label -match '^\d{4}-\d{2}-\d{2}_(.+)$') { $label = $Matches[1] }
        $links += "[$label]($prefix$(Esc $day.Name)/$(Esc $f.Name))"
    }
    "- **$($day.Name)** : " + ($links -join " | ")
}

function Get-Days($sectionDir) {
    Get-ChildItem $sectionDir.FullName -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}$' } |
        Sort-Object Name -Descending
}

$sections = Get-ChildItem $Repo -Directory |
            Where-Object { $_.Name -ne "logs" -and $_.Name -notlike ".*" } |
            Sort-Object Name

$root = @("# stock_report", "", "Report archive. **Newest first** - the folder listing above is sorted the other way.", "Latest $Max dates per section; full history in each section README.", "")

foreach ($s in $sections) {
    $days = @(Get-Days $s)
    if ($days.Count -eq 0) { continue }

    $root += "## $($s.Name)"
    $root += ""
    foreach ($d in ($days | Select-Object -First $Max)) {
        $line = Get-DayLine $d "$(Esc $s.Name)/"
        if ($line) { $root += $line }
    }
    if ($days.Count -gt $Max) { $root += "- ... $($days.Count - $Max) older dates: [full list]($(Esc $s.Name)/README.md)" }
    $root += ""

    $sec = @("# $($s.Name)", "", "**Newest first.**", "")
    foreach ($d in $days) {
        $line = Get-DayLine $d ""
        if ($line) { $sec += $line }
    }
    $sec += ""
    [System.IO.File]::WriteAllText((Join-Path $s.FullName "README.md"), ($sec -join "`n"), $utf8)
}

[System.IO.File]::WriteAllText((Join-Path $Repo "README.md"), ($root -join "`n"), $utf8)
