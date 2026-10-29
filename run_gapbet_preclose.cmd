@echo off
REM Scheduler wrapper (separate repo) - preclose mode. Runs the skill in MAIN, then copies+pushes reports here.
REM Holiday guard added 2026-10-05: this wrapper was the only one of the three without it, so the
REM 10-05 substitute holiday ran a preclose scan against a closed market.
REM One attempt per scheduler instance (2026-10-29): the retry is the gapbet_preclose_catchup task
REM at 15:00 (the last start that still finishes before the 15:20 closing auction), not a loop in
REM this console, because a Ctrl+C (0xC000013A) kills this cmd.exe along with claude (10-26, 10-29).
REM A missing report is announced by report_watch.ps1 (gapbet_report_watch, 15:25).
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
set LOG=%LOGDIR%\gapbet_preclose_%TODAY%.log
set REPORT=%MAIN%\docs\gapbet\gapbet_preclose_%TODAY%.md

REM ---- an earlier instance already produced today's report: the catch-up has nothing to do.
if exist "%REPORT%" (
  echo [%TIME%] report already exists -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

REM ---- the other task's run is still going: let it finish rather than start a second one.
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\skill_running.ps1" -Prompt "/gapbet preclose"
if errorlevel 1 (
  echo [%TIME%] a preclose run is already in progress -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

REM ---- holiday guard: no bars today means the market never opened, so there is no closing auction.
python "%MAIN%\reports\market_open.py" %TODAY% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [%TIME%] market closed on %TODAY% -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

echo [%TIME%] run >> "%LOG%"
"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet preclose" --dangerously-skip-permissions --mcp-config "%MAIN%\reports\mcp_headless.json" --strict-mcp-config --allowedTools "Bash WebFetch WebSearch Read Write Edit Glob Grep Skill mcp__playwright__browser_navigate mcp__playwright__browser_snapshot mcp__playwright__browser_click mcp__playwright__browser_close" >> "%LOG%" 2>&1
if not exist "%REPORT%" echo [%TIME%] FAILED: no report -- the catch-up task retries >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_main.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet
endlocal
