::/*Author：DDL
:: *Date：Mar. 7, 2016    */

@ECHO off
SETLOCAL ENABLEDELAYEDEXPANSION 
chcp 65001
SET interface_name="乙太網路"

::---------------GotAdmin---------------
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

::------------Set IP--------------------
:choose_dorm
    CLS
    ECHO Set IP
    ECHO.
    SET /p "dorm_num=Which Dorm ('Upper case' ABCDEFGHL, 1234, T:Go test, Q:Exit)? " || GOTO choose_dorm
    if %dorm_num%==T CLS & GOTO ping_test
    if %dorm_num%==Q GOTO END
    GOTO set_Sub_Mask
    
:set_Sub_Mask
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if %%a==%dorm_num%_Mask (
            ECHO Sub_Mask: %%b
            SET Sub_Mask=%%b
            GOTO set_D_Gate
        )
    )
    GOTO if_set_again

:set_D_Gate
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if %%a==%dorm_num%_Gate (
            ECHO D_Gate: %%b
            SET D_Gate=%%b
            GOTO choose_room
        )
    )
    GOTO if_set_again

:choose_room
    ECHO.
    SET /p room_num=Which room and bed num (ex: xxx-x)? 
    for /f "tokens=1-2 delims= " %%a in (dorm.txt) do (
        if %%a==%dorm_num%%room_num% (
            ECHO IP_Addr: %%b
            SET IP_Addr=%%b
            GOTO set_ip
        )
    )
    GOTO if_set_again

:set_ip
    netsh interface ip set address name=%interface_name% static %IP_Addr% %Sub_Mask% %D_Gate% 1
    IF ERRORLEVEL 1 GOTO if_set_again
    IF ERRORLEVEL 0 ipconfig /renew && CLS & GOTO ping_test
    
:if_set_again
    CHOICE /C YN /M "Error input, set again(Y), go test(N)?"
    IF ERRORLEVEL 2 CLS & GOTO ping_test
    IF ERRORLEVEL 1 GOTO choose_dorm
::--------------------------------------

::-----------Ping Test------------------
:ping_test
    ECHO Ping Test Opts
    ECHO.
    ECHO 1.ping 8.8.8.8       2.ping fb.com     3.ipconfig /all
    ECHO.
    ECHO 4.ping "parameters"  5.Back to Set IP           6.Exit
    ECHO.
    CHOICE /C 123456
    IF ERRORLEVEL 6 GOTO END
    IF ERRORLEVEL 5 GOTO choose_dorm
    IF ERRORLEVEL 4 CLS & GOTO test4
    IF ERRORLEVEL 3 CLS & GOTO test3
    IF ERRORLEVEL 2 CLS & GOTO test2
    IF ERRORLEVEL 1 CLS & GOTO test1
    ::choice fail
    CLS
    ECHO Error input, please input again.
    ECHO.
    GOTO ping_test
    
:test4
    ECHO.
    SET /p ping_cmd=Enter command: ping 
    %SystemRoot%\system32\ping.exe %ping_cmd%
    pause && CLS & GOTO ping_test

:test3
    %SystemRoot%\system32\ipconfig /all
    pause && CLS & GOTO ping_test
    
:test2
    %SystemRoot%\system32\ping.exe fb.com
    pause && CLS & GOTO ping_test    
    
:test1
    %SystemRoot%\system32\ping.exe 8.8.8.8
    pause && CLS & GOTO ping_test
::--------------------------------------

:END
ENDLOCAL