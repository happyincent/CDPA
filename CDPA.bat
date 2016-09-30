::/*Author：DDL
:: *Date：Sep. 30, 2016    */

@ECHO off
SETLOCAL enableDelayedExpansion
chcp 65001

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

::-------------------Main-------------------
:main
    SET if_set_gateway=0
    SET interface_name=
    CLS
    ECHO 1.Go "Set IP & Sub_Mask & D_Gate"
    ECHO.
    ECHO 2.Go "Ping Test"
    ECHO.
    ECHO 3.Exit
    ECHO.
    CHOICE /C 123
    IF ERRORLEVEL 3 GOTO END
    IF ERRORLEVEL 2 GOTO ping_test
    IF ERRORLEVEL 1 CLS & GOTO check_if_set
    ::choice fail
    GOTO main

::-------------------check if set-------------------
:check_if_set
    for /F "tokens=1-2 delims= " %%a in (CDPA.bat) do (
        SET interface_name=%%b
    )
    if "%interface_name%"=="" GOTO set_interface_name
    GOTO choose_dorm

::-------------------Set IP & Sub_Mask & D_Gate-------------------
:set_interface_name
    set count=0
    set choices=""

    CLS
    ECHO Set IP ^& Sub_Mask ^& D_Gate - select interface name
    ECHO.
    
    for /f "skip=2 tokens=3*" %%A in ('netsh interface show interface') do (
        set /a count+=1
        set arr!count!=%%B
        set choices=!choices!!count!
        echo [!count!] %%B
    )
    
    ECHO.    
    choice /C !choices! /M "Select Ethernet Interface: " /N
    set level=%ERRORLEVEL%

    ::choice fail
    if %level% EQU 0 GOTO set_interface_name
    
    ::choice success    
    set interface_name=!arr%level%!
    
    ::write to file
    ECHO.>> CDPA.bat
    ECHO ::REM %interface_name%>> CDPA.bat

    ::goto next
    GOTO choose_dorm
    
:choose_dorm
    CLS
    ECHO Set IP ^& Sub_Mask ^& D_Gate - choose dorm and room
    ECHO.
    ECHO /* Case-Insensitive */
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
            GOTO if_change_set
        )
    )
    GOTO if_set_again

:set_interface
    netsh interface ipv4 set address name=%interface_name% static %IP_Addr% %Sub_Mask% %D_Gate% 1
    IF ERRORLEVEL 1 pause & GOTO set_interface_name
    IF ERRORLEVEL 0 ipconfig /renew %interface_name% && GOTO set_dnsservers
    
:set_dnsservers
    netsh interface ipv4 delete dnsservers name=%interface_name% all >nul
    netsh interface ipv4 set dnsserver name=%interface_name% static 140.117.205.1 primary validate=no
    netsh interface ipv4 add dnsserver name=%interface_name% 8.8.8.8 index=2 validate=no
    pause
    GOTO ping_test
    
:if_set_again
    CHOICE /C YN /M "Error input, set again(Y), go test(N)?" /N
    IF ERRORLEVEL 2 GOTO ping_test
    IF ERRORLEVEL 1 GOTO choose_dorm
    ::choice fail
    GOTO if_set_again
    
:if_change_set
    ECHO.
    CHOICE /C 01 /M "Change IP Setting, Yes(1), No(0) go to Ping Test?" /N
    IF ERRORLEVEL 2 GOTO set_interface
    IF ERRORLEVEL 1 GOTO ping_test
    ::choice fail
    GOTO if_change_set

::-------------------Ping Test-------------------
:ping_test
    CLS
    ECHO Ping Test Opts
    ECHO.
    ECHO 1.ping 8.8.8.8     2.ping -t 8.8.8.8   3.ping "parameters"
    ECHO.
    ECHO 4.ping gateway     5.ping arista       6.ipconfig /all
    ECHO.
    ECHO 7.Go "Set IP & Sub_Mask & D_Gate"      8.Exit
    ECHO.
    CHOICE /C 12345678
    IF ERRORLEVEL 8 GOTO END
    IF ERRORLEVEL 7 GOTO check_if_set
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
    %SystemRoot%\system32\ping.exe -t 8.8.8.8
    pause && GOTO ping_test    
    
:test1
    %SystemRoot%\system32\ping.exe 8.8.8.8
    pause && GOTO ping_test
::--------------------------------------

:END
ENDLOCAL
