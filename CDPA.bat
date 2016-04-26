::/*Author：DDL
:: *Date：April. 27, 2016    */

@ECHO off
SETLOCAL
chcp 65001
SET interface_name="乙太網路"

::-------------------GotAdmin-------------------
REM --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    ECHO Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    ECHO Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    ECHO UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
::--------------------------------------

::-------------------Main-------------------
:main
    SET if_set_gateway=0
    CLS
    ECHO 1.Goto "Set IP & Sub_Mask & D_Gate"
    ECHO.
    ECHO 2.Goto "Ping Test"
    ECHO.
    ECHO 3.Exit
    ECHO.
    CHOICE /C 123
    IF ERRORLEVEL 3 GOTO END
    IF ERRORLEVEL 2 GOTO ping_test
    IF ERRORLEVEL 1 CLS & GOTO choose_dorm
    ::choice fail
    GOTO main
::--------------------------------------

::-------------------Set IP & Sub_Mask & D_Gate-------------------
:choose_dorm
    CLS
    ECHO Set IP ^& Sub_Mask ^& D_Gate
    ECHO.
    ECHO /* The following choice is Case-Insensitive */
    ECHO.
    SET /p "dorm_num=Which Dorm (ABCDEFGHL, 1234, T:Go "Ping Test", Q:Exit)? " || GOTO choose_dorm
    if /I %dorm_num%==T GOTO ping_test
    if /I %dorm_num%==Q GOTO END
    GOTO set_Sub_Mask
    
:set_Sub_Mask
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if /I %%a==%dorm_num%_Mask (
            ECHO Sub_Mask: %%b
            SET Sub_Mask=%%b
            GOTO set_D_Gate
        )
    )
    GOTO if_set_again

:set_D_Gate
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if /I %%a==%dorm_num%_Gate (
            ECHO D_Gate: %%b
            SET D_Gate=%%b
            SET if_set_gateway=1
            GOTO choose_room
        )
    )
    GOTO if_set_again

:choose_room
    ECHO.
    SET /p room_num=Which room and bed num (ex: xxx-x)? 
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if /I %%a==%dorm_num%%room_num% (
            ECHO IP_Addr: %%b
            SET IP_Addr=%%b
            GOTO set_interface
        )
    )
    GOTO if_set_again

:set_interface
    netsh interface ip set address name=%interface_name% static %IP_Addr% %Sub_Mask% %D_Gate% 1
    pause
    IF ERRORLEVEL 1 GOTO if_set_again
    IF ERRORLEVEL 0 ipconfig /renew && GOTO ping_test
    
:if_set_again
    CHOICE /C YN /M "Error input, set again(Y), go test(N)?"
    IF ERRORLEVEL 2 GOTO ping_test
    IF ERRORLEVEL 1 GOTO choose_dorm
::--------------------------------------


::-------------------Ping Test-------------------
:ping_test
    CLS
    ECHO Ping Test Opts
    ECHO.
    ECHO 1.ping 8.8.8.8     2.ping fb.com     3.ping "parameters"
    ECHO.
    ECHO 4.ping gateway     5.ping arista     6.ipconfig     /all
    ECHO.
    ECHO 7.Back to "Set IP & Sub_Mask & D_Gate"            8.Exit
    ECHO.
    CHOICE /C 12345678
    IF ERRORLEVEL 8 GOTO END
    IF ERRORLEVEL 7 GOTO choose_dorm
    IF ERRORLEVEL 6 CLS & GOTO test6
    IF ERRORLEVEL 5 CLS & GOTO test5
    IF ERRORLEVEL 4 CLS & GOTO test4
    IF ERRORLEVEL 3 CLS & GOTO test3
    IF ERRORLEVEL 2 CLS & GOTO test2
    IF ERRORLEVEL 1 CLS & GOTO test1
    ::choice fail
    GOTO ping_test
    
:test6
    %SystemRoot%\system32\ipconfig /all
    pause && GOTO ping_test
    
:test5
    %SystemRoot%\system32\ping.exe 140.117.232.69
    pause && GOTO ping_test
    
:test4
    if %if_set_gateway%==0 ECHO haven't set deafault gateway & ECHO. & pause & GOTO ping_test
    %SystemRoot%\system32\ping.exe %D_Gate%
    pause && GOTO ping_test
    
:test3
    ECHO.
    SET /p "ping_cmd=Enter command: ping " || GOTO test3
    %SystemRoot%\system32\ping.exe %ping_cmd%
    pause && GOTO ping_test
   
:test2
    %SystemRoot%\system32\ping.exe fb.com
    pause && GOTO ping_test    
    
:test1
    %SystemRoot%\system32\ping.exe 8.8.8.8
    pause && GOTO ping_test
::--------------------------------------

:END
ENDLOCAL