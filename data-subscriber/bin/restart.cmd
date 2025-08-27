@REM #############################################
@REM # 'restart' script
@REM # Usage: restart.cmd {instance {springFile.xml}}
@REM #############################################

call stop.cmd %~1 %~2

call start.cmd %~1 %~2
