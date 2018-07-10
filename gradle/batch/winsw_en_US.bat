@echo off
Setlocal enabledelayedexpansion
::CODER BY xiaoyao9184 1.0 beta
::TIME 2018-07-10
::FILE WINSW
::DESC WINSW Command navigation




:v

set tip=WINSW Tool£ºCommand navigation
set ver=1.0
set winswName=%~n0

set echo_select=Please enter the serial number!
set echo_enter=Please enter the WinSW program path
set echo_auth_good=has administrator permission
set echo_auth_bad=no administrator permission
set echo_-install=[1]Installation service
set echo_-uninstall=[2]Uninstall service
set echo_-start=[3]start the service
set echo_-stop=[4]stop service
set echo_-restart=[5]restart service
set echo_-status=[6]service status




:title

title %tip% %ver%

echo WINSW Tool£ºCommand navigation
echo Can be closed after the run ends
echo ...




:cd

%~d0
cd %~dp0
cd..




:check

set TempFile_Name=%SystemRoot%\System32\BatTestUACin_SysRt%Random%.batemp
echo %TempFile_Name% 1>nul

( echo "BAT Test UAC in Temp" >%TempFile_Name% ) 1>nul 2>nul
 if exist %TempFile_Name% (
 echo %echo_auth_good%
 del /f /q %TempFile_Name%
 goto auth_done
) else (
 echo %echo_auth_bad%
 goto auth_get
)




:auth_get

%1 %2
ver|find "5.">nul&&goto :st
mshta vbscript:createobject("shell.application").shellexecute("%~s0","goto :st","","runas",1)(window.close)&goto :eof




:st

copy "%~0" "%windir%\system32\"
goto :auth_done




:auth_done

set winswExe=%~d0%~p0%winswName%.exe

if exist %winswExe% (
    goto loop
)

echo %winswExe% doesn't exist
set /p winswExe=%echo_enter%




:loop

echo %echo_-install%
echo %echo_-uninstall%
echo %echo_-start%
echo %echo_-stop%
echo %echo_-restart%
echo %echo_-status%

choice /c 123456 /m %echo_select%
	if !errorlevel! equ 1 goto c-install
	if !errorlevel! equ 2 goto c-uninstall
	if !errorlevel! equ 3 goto c-start
	if !errorlevel! equ 4 goto c-stop
	if !errorlevel! equ 5 goto c-restart
	if !errorlevel! equ 6 goto c-status

goto exit




:c-install

call %winswExe% install
goto loop


:c-uninstall

call %winswExe% uninstall
goto loop


:c-start

call %winswExe% start
goto loop


:c-stop

call %winswExe% stop
goto loop


:c-restart

call %winswExe% restart
goto loop


:c-status

call %winswExe% status
goto loop




:exit

exit \b
