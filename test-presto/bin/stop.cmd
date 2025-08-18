@REM #############################################
@REM # 'stop' script
@REM # Usage: stop.cmd {instance}
@REM #############################################

echo off
setlocal enableextensions enabledelayedexpansion

set ERROR_CODE=0

set "APP_HOME_RELATIVE=%~dp0.."

pushd %APP_HOME_RELATIVE%

set APP_HOME=%CD%

set "INSTANCE=%~1"

set "PROPERTIES_FILE=config\config.properties"
if not exist "%PROPERTIES_FILE%" (
	echo "Properties file %PROPERTIES_FILE% does not exist" >&2
	goto error
)

set "APP_NAME="
set "APP_NAME_PROPERTY=appName"
FOR /F "tokens=1,2 delims==" %%A IN (%PROPERTIES_FILE%) DO (
	IF "%%A"=="%APP_NAME_PROPERTY%" SET "APP_NAME=%%B"
)
if "%APP_NAME%"=="" (
	echo Cannot read property '%APP_NAME_PROPERTY%' from properties file %PROPERTIES_FILE%. Property does not exist. >&2
	goto error
)

echo ===============================================================================
echo                            stop %APP_NAME%
echo ===============================================================================

set "PID="
set "PID_FILE=%APP_HOME%\var\%APP_NAME%%INSTANCE%.pid"
if exist "%PID_FILE%" (
	set /p PID=<%PID_FILE%
	@REM check PID is numeric
	SET /a PID=!PID!+0
	IF NOT !PID!==0 (
		@REM find process with PID
		for /f "skip=1 usebackq" %%A IN (`wmic process where "name='java.exe' and ProcessId=!PID!" get ProcessId`) do (
			if "%%A"=="!PID!" (
				echo Stopping Madrigal process with PID: !PID!
				taskkill /F /PID %%A
				goto end
			)
		)
	)
)

goto end

:error
set ERROR_CODE=1

:end
popd
endlocal & set ERROR_CODE=%ERROR_CODE%

cmd /C exit /B %ERROR_CODE%
