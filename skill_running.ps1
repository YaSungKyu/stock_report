# Exit 1 when a headless claude run of the given skill prompt is already in progress.
# The catch-up triggers live in separate scheduled tasks (the original tasks reject edits from a
# non-elevated session), so the scheduler's IgnoreNew cannot stop a catch-up instance from
# starting a second scan next to a slow first one. Matching the claude command line instead of
# a lock file means a killed instance leaves nothing stale behind. ASCII only (cp949-safe).
param([Parameter(Mandatory = $true)][string]$Prompt)
$pat = '*-p "' + $Prompt + '"*'
$hit = Get-CimInstance Win32_Process -Filter "Name='claude.exe'" | Where-Object { $_.CommandLine -like $pat }
if ($hit) { exit 1 }
exit 0
