@echo off
REM Scheduler wrapper - gapbet_review. Runs the review skill in MAIN, then archives+pushes the daily review here.
setlocal
set MAIN=C:\Projects\ai
cd /d "%MAIN%"
set LOGDIR=%MAIN%\reports\logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set TODAY=%%d
"C:\Users\2019439\.local\bin\claude.exe" -p "/gapbet_review" --allowedTools "Bash Read Write Edit Glob Grep Skill" > "%LOGDIR%\gapbet_review_%TODAY%.log" 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%MAIN%\reports\commit_push_reports.ps1" gapbet_review
endlocal
