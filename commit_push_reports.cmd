@echo off
REM Archive the freshly generated report into THIS separate repo, organized by
REM date folder + timestamp filename (no preclose/report distinction), then push to public.
REM Usage: commit_push_reports.cmd <subdir>   (subdir = gapbet | invest; default gapbet)
setlocal
set GIT="C:\Program Files\Git\cmd\git.exe"
set MAIN=C:\Projects\ai
set REPO=%MAIN%\reports
set SUB=%1
if "%SUB%"=="" set SUB=gapbet
if not exist "%REPO%\logs" mkdir "%REPO%\logs"
set GLOG=%REPO%\logs\git.log
set SRC=%MAIN%\docs\%SUB%
if not exist "%SRC%" ( echo [%DATE% %TIME%] no source dir %SRC%>> "%GLOG%" & exit /b 0 )
for /f %%d in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set DAY=%%d
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HHmm"') do set STAMP=%%t
set NEWEST=
for /f "delims=" %%f in ('dir /b /o-d "%SRC%\*.md" 2^>nul') do if not defined NEWEST set NEWEST=%%f
if not defined NEWEST ( echo [%STAMP%] no md in %SRC%>> "%GLOG%" & exit /b 0 )
if not exist "%REPO%\%SUB%\%DAY%" mkdir "%REPO%\%SUB%\%DAY%"
copy /Y "%SRC%\%NEWEST%" "%REPO%\%SUB%\%DAY%\%STAMP%.md" >> "%GLOG%" 2>&1
cd /d "%REPO%"
%GIT% add -A
%GIT% diff --cached --quiet
if %ERRORLEVEL%==0 ( echo [%STAMP%] no report changes>> "%GLOG%" & exit /b 0 )
%GIT% commit -m "reports: %SUB% %STAMP%">> "%GLOG%" 2>&1
%GIT% push origin HEAD>> "%GLOG%" 2>&1
if %ERRORLEVEL%==0 (echo [%STAMP%] push OK>> "%GLOG%") else (echo [%STAMP%] push FAILED - see above>> "%GLOG%")
endlocal
