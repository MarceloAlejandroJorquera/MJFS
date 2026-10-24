@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "PS5=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PS5%" (
  echo [MJFS PUBLISH] ERROR: Windows PowerShell 5.1 not found.
  exit /b 1
)
"%PS5%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\publish\Publish-MJFSv1.ps1" %*
exit /b %ERRORLEVEL%
