@echo off
REM Scheduler wrapper (separate repo) - preclose mode. Runs the skill in MAIN, then copies+pushes reports here.
REM Holiday guard added 2026-10-05: this wrapper was the only one of the three without it, so the
REM 10-05 substitute holiday ran a preclose scan against a closed market.
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
set LOG=%LOGDIR%\gapbet_preclose_%TODAY%.log

REM ---- holiday guard: no bars today means the market never opened, so there is no closing auction.
python "%MAIN%\reports\market_open.py" %TODAY% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [%TIME%] market closed on %TODAY% -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet preclose" --dangerously-skip-permissions --mcp-config "%MAIN%\reports\mcp_headless.json" --strict-mcp-config --allowedTools "Bash WebFetch WebSearch Read Write Edit Glob Grep Skill mcp__playwright__browser_navigate mcp__playwright__browser_snapshot mcp__playwright__browser_click mcp__playwright__browser_close" >> "%LOG%" 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_main.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet
endlocal
