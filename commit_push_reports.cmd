@echo off
REM Copy freshly generated reports from the MAIN project's docs/ into THIS separate repo, then push to public.
setlocal
set GIT="C:\Program Files\Git\cmd\git.exe"
set MAIN=C:\Projects\ai
set REPO=%MAIN%\reports
if not exist "%REPO%\logs" mkdir "%REPO%\logs"
if not exist "%REPO%\gapbet" mkdir "%REPO%\gapbet"
if not exist "%REPO%\invest" mkdir "%REPO%\invest"
set GLOG=%REPO%\logs\git.log
xcopy /Y /Q "%MAIN%\docs\gapbet\*.md" "%REPO%\gapbet\" >> "%GLOG%" 2>&1
xcopy /Y /Q "%MAIN%\docs\invest\*.md" "%REPO%\invest\" >> "%GLOG%" 2>&1
cd /d "%REPO%"
%GIT% add -A
%GIT% diff --cached --quiet
if %ERRORLEVEL%==0 (
  echo [%DATE% %TIME%] no report changes>> "%GLOG%"
  exit /b 0
)
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmm"') do set STAMP=%%t
%GIT% commit -m "reports: auto %STAMP%">> "%GLOG%" 2>&1
%GIT% push origin HEAD>> "%GLOG%" 2>&1
if %ERRORLEVEL%==0 (echo [%STAMP%] push OK>> "%GLOG%") else (echo [%STAMP%] push FAILED - see above>> "%GLOG%")
endlocal
