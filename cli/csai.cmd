@echo off
setlocal EnableExtensions
set "DIR=%~dp0"
if defined CS_AI_PYTHON (
  "%CS_AI_PYTHON%" "%DIR%csai.py" %*
  exit /b %ERRORLEVEL%
)
if defined PYTHON (
  "%PYTHON%" "%DIR%csai.py" %*
  exit /b %ERRORLEVEL%
)
where py >nul 2>&1
if %ERRORLEVEL%==0 (
  py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1
  if %ERRORLEVEL%==0 (
    py -3 "%DIR%csai.py" %*
    exit /b %ERRORLEVEL%
  )
)
where python >nul 2>&1
if %ERRORLEVEL%==0 (
  python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)" >nul 2>&1
  if %ERRORLEVEL%==0 (
    python "%DIR%csai.py" %*
    exit /b %ERRORLEVEL%
  )
)
echo cs.AI CLI needs Python 3.9+. Install Python and tick "Add python.exe to PATH", or set CS_AI_PYTHON.
exit /b 1
