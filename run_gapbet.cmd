@echo off
REM Scheduler wrapper (separate repo). Runs the skill in the MAIN project, then copies+pushes reports here.
REM Guards added 2026-08-21 (pending_changes.md item I): skip holidays, retry when no report was
REM produced. Three scheduled runs were lost to Ctrl+C / API 529 / expired OAuth and each loss
REM burned a compounding slot silently -- a missing report is invisible until the next review.
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
set LOG=%LOGDIR%\gapbet_%TODAY%.log
set REPORT=%MAIN%\docs\gapbet\gapbet_report_%TODAY%.md

REM ---- holiday guard: no bars today means the market never opened, so there is nothing to scan.
REM ---- bound every place a run leaves files. Runs BEFORE the scan, so the previous
REM run's artifacts stay inspectable until the next run starts and no older ones pile up.
echo [%TIME%] cleanup >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\cleanup_artifacts.ps1" >> "%LOG%" 2>&1

python "%MAIN%\reports\market_open.py" %TODAY% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [%TIME%] market closed on %TODAY% -- nothing to do >> "%LOG%"
  endlocal & exit /b 0
)

REM ---- run, and retry while no report file appeared. 5 min apart, at most 3 attempts.
set ATTEMPT=0
:run
set /a ATTEMPT+=1
echo [%TIME%] attempt %ATTEMPT% >> "%LOG%"
"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet" --dangerously-skip-permissions --mcp-config "%MAIN%\reports\mcp_headless.json" --strict-mcp-config --allowedTools "Bash WebFetch WebSearch Read Write Edit Glob Grep Skill mcp__playwright__browser_navigate mcp__playwright__browser_snapshot mcp__playwright__browser_click mcp__playwright__browser_close" >> "%LOG%" 2>&1
if exist "%REPORT%" goto done
if %ATTEMPT% GEQ 3 (
  echo [%TIME%] FAILED: no report after %ATTEMPT% attempts >> "%LOG%"
  goto done
)
echo [%TIME%] no report yet -- waiting 5 min >> "%LOG%"
powershell -NoProfile -Command "Start-Sleep -Seconds 300"
goto run

:done
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_main.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet
endlocal
