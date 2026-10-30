@echo off
REM Scheduler wrapper (separate repo). Runs the skill in the MAIN project, then copies+pushes reports here.
REM Guards added 2026-08-21 (pending_changes.md item I): skip holidays, retry when no report was
REM produced. Three scheduled runs were lost to Ctrl+C / API 529 / expired OAuth and each loss
REM burned a compounding slot silently -- a missing report is invisible until the next review.
REM One attempt per scheduler instance (2026-10-29): the retries are the gapbet_postclose_catchup
REM task (16:10 / 17:10 / 18:10 / 19:10, inside the NXT after-market) instead of a loop in this
REM console, because a Ctrl+C (0xC000013A) kills this cmd.exe along with claude and the in-console
REM retry never ran (09-17, 10-26). A missing report is announced by report_watch.ps1
REM (gapbet_report_watch, 19:50) -- the weekly-limit failures reset after 20:00, so being told is
REM the only recovery there.
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
set LOG=%LOGDIR%\gapbet_%TODAY%.log
set REPORT=%MAIN%\docs\gapbet\gapbet_report_%TODAY%.md

REM ---- an earlier instance already produced today's report: the catch-up has nothing to do.
REM Checked before cleanup so a finished day keeps its artifacts inspectable.
if exist "%REPORT%" (
  echo [%TIME%] report already exists -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

REM ---- the other task's scan is still going: let it finish rather than start a second one.
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\skill_running.ps1" -Prompt "/gapbet"
if errorlevel 1 (
  echo [%TIME%] a scan is already in progress -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

REM ---- bound every place a run leaves files. Runs BEFORE the scan, so the previous
REM run's artifacts stay inspectable until the next run starts and no older ones pile up.
echo [%TIME%] cleanup >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\cleanup_artifacts.ps1" >> "%LOG%" 2>&1

REM ---- holiday guard: no bars today means the market never opened, so there is nothing to scan.
python "%MAIN%\reports\market_open.py" %TODAY% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [%TIME%] market closed on %TODAY% -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

echo [%TIME%] run >> "%LOG%"
"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet" --dangerously-skip-permissions --mcp-config "%MAIN%\reports\mcp_headless.json" --strict-mcp-config --allowedTools "Bash WebFetch WebSearch Read Write Edit Glob Grep Skill mcp__playwright__browser_navigate mcp__playwright__browser_snapshot mcp__playwright__browser_click mcp__playwright__browser_close" >> "%LOG%" 2>&1
if not exist "%REPORT%" echo [%TIME%] FAILED: no report -- the catch-up task retries >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_main.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet
endlocal
