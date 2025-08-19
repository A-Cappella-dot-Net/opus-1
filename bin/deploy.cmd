echo off
setlocal enableextensions enabledelayedexpansion

set "APP_HOME_RELATIVE=%~dp0.."
pushd %APP_HOME_RELATIVE%

set APPS_HOME=%CD%
echo APPS_HOME: %APPS_HOME%

set TARGET_MACHINE=%~1

@REM scp -p %APPS_HOME%\credentials\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

scp -p %APPS_HOME%\daemons-aeron\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

scp -p %APPS_HOME%\exchange\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\lh\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\m-cache\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\market-maker\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\mid-feed\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\sys\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\serializer\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

@REM scp -p %APPS_HOME%\test-aeron\build\dist\*.gz %TARGET_MACHINE%:/opt/madrigal/releases

ssh %TARGET_MACHINE% "cd /opt/madrigal/bin;./unpack-all.sh"

goto end

:error
set ERROR_CODE=1

:end
popd
endlocal & set ERROR_CODE=%ERROR_CODE%

cmd /C exit /B %ERROR_CODE%
