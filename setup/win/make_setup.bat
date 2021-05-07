@echo off

if (%1) == () goto usage
if (%2) == () goto usage

make -C ../.. clean all LAZARUS_DIR="%1"
if errorlevel 1 goto err

if not (%CODECERT%) == () (
  signtool.exe sign /as /fd sha256 /tr "http://timestamp.digicert.com" /td sha256 /d "Transmission Remote GUI" /du "https://sourceforge.net/projects/transgui/" /f "%CODECERT%" /v ..\..\transgui.exe
  if errorlevel 1 goto err
)

set ISC=%~2

"%ISC%\iscc.exe" "/ssigntool=signtool.exe $p" setup.iss
if errorlevel 1 goto err

exit /b 0

:usage
echo "Usage: %~nx0 <lazarus_dir> <inno_setup_dir>"

:err
pause
exit /b 1
