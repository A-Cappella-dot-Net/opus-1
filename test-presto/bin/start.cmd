@REM #############################################
@REM # 'start' script
@REM # Usage: start.cmd {instance {springFile.xml}}
@REM #############################################

echo off
setlocal enableextensions enabledelayedexpansion

set ERROR_CODE=0

set "APP_HOME_RELATIVE=%~dp0.."

pushd %APP_HOME_RELATIVE%

set APP_HOME=%CD%

set "INSTANCE=%~1"
SET "SPRING_XML=%~2"

call "%APP_HOME%\bin\setenv.cmd"

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
echo                            start %APP_NAME%
echo ===============================================================================

if not exist "%APP_HOME%\logs" (
	mkdir "%APP_HOME%\logs"
)

if not exist "%APP_HOME%\var" (
	mkdir "%APP_HOME%\var"
)

if "%JAVA_HOME%"=="" (
	for %%i in (java.exe) do set "JAVA_CMD=%%~$PATH:i"
) else (
	set JAVA_CMD="%JAVA_HOME%"\bin\java.exe
)

if !JAVA_CMD!=="" (
	echo The JAVA_HOME environment variable is not defined correctly >&2
	echo java.exe is not found. Please ensure that JDK is installed. >&2
	goto error
)

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
				echo Another instance found PID: !PID! >&2
				goto error
			)
		)
	)
)

set "CURRENT_DATE=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set CURRENT_DATE=%CURRENT_DATE: =0%

set "LOG_NAME=%APP_HOME%\logs\%APP_NAME%%INSTANCE%-%CURRENT_DATE%.log"
@REM echo Log is redirected to file: %LOG_NAME%

set "GC_LOG_NAME=%APP_HOME%\logs\%APP_NAME%%INSTANCE%-%CURRENT_DATE%-gc.log"
@REM echo GC log is redirected to file: %GC_LOG_NAME%

set "VM_ARGS=-Dinstance=%INSTANCE% -Xms%HEAP_SIZE% -Xmx%HEAP_SIZE% %GC_ARGS%%GC_LOG_NAME%"

set "BOOT_PATH=-Xbootclasspath/a:%APP_HOME%\lib\boot\win\*"

set "CLASSPATH=%APP_HOME%\app;%APP_HOME%\lib\*;%APP_HOME%\lib\dependencies\*"
@REM echo Classpath: !CLASSPATH!

set "JAVA_CMD=%JAVA_CMD% -Duser.dir=%APP_HOME% %VM_ARGS% %BOOT_PATH% -cp !CLASSPATH! net.a_cappella.continuo.Main %SPRING_XML%"
echo Running command: %JAVA_CMD%

start "madrigal: %APP_NAME%" cmd /c "!JAVA_CMD! > !LOG_NAME! 2>&1"

timeout 2 > nul 2>&1

set "PROCESS_QUERY_STR="name='java.exe' and commandline like '%%-Duser.dir=%APP_HOME%%%' and commandline like '%%%INSTANCE%%%'""
set "PROCESS_QUERY_STR=%PROCESS_QUERY_STR:\=\\%"

set "PID="
for /f "skip=1 usebackq" %%A IN (`wmic process where %PROCESS_QUERY_STR% get ProcessId`) do (
	@REM check PID is numeric
	SET /a WMIC_RESULT=%%A+0
	if not !WMIC_RESULT!==0 (
		set "PID=%%~A"
		goto end_pid_loop
	)
)
:end_pid_loop

if not "!PID!"=="" (
	echo %APP_NAME%%INSTANCE% PID: %PID%
	echo %PID%>%PID_FILE%
)

goto end

:error
set ERROR_CODE=1

:end
popd
endlocal & set ERROR_CODE=%ERROR_CODE%

cmd /C exit /B %ERROR_CODE%
