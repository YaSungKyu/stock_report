@echo off
REM Scheduler wrapper - gapbet_review. Runs the review skill in MAIN, then archives+pushes the daily review here.
REM Guards added 2026-08-21 (pending_changes.md item I): same holiday skip and retry as run_gapbet.
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
set LOG=%LOGDIR%\gapbet_review_%TODAY%.log
set REVIEW=%MAIN%\docs\gapbet_review\review_%TODAY%.md

python "%MAIN%\reports\market_open.py" %TODAY% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [%TIME%] market closed on %TODAY% -- nothing to review >> "%LOG%"
  endlocal & exit /b 0
)

set ATTEMPT=0
:run
set /a ATTEMPT+=1
echo [%TIME%] attempt %ATTEMPT% >> "%LOG%"
"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet_review" --dangerously-skip-permissions --allowedTools "Bash Read Write Edit Glob Grep Skill" >> "%LOG%" 2>&1
if exist "%REVIEW%" goto done
if %ATTEMPT% GEQ 3 (
  echo [%TIME%] FAILED: no review after %ATTEMPT% attempts >> "%LOG%"
  goto done
)
echo [%TIME%] no review yet -- waiting 5 min >> "%LOG%"
powershell -NoProfile -Command "Start-Sleep -Seconds 300"
goto run

:done
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_main.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet_review
endlocal
