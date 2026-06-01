@echo off
title VRChat Timeout Restart Utility 20230607 @gin_vrc

REM == SETTINGS ===

REM Path to VRChat executable or shortcut (optional)
SET _VRCSHORTCUT=%USERPROFILE%\Desktop\VRChat.lnk

REM Path to VRC Profile directory (no trailing slash)
SET _VRCPROFILE=%APPDATA%\..\LocalLow\VRChat\VRChat

REM Time in seconds to check for disconnects.
SET _SLEEPSECS=300

REM Delay in seconds before restarting on disconnect.
SET _GRACESECS=60

REM === FIND REQUIREMENTS ===
REM Windows 7+ required

IF NOT EXIST "%_VRCSHORTCUT%" (
ECHO Please set VRChat executable path! Using system URI handler.
SET _VRCSHORTCUT=0
)

IF NOT EXIST "%_VRCPROFILE%" (
ECHO Please set VRChat profile path!
EXIT /B 1
)

tasklist /? >NUL
IF %ERRORLEVEL% EQU 9009 (
ECHO No "tasklist"!
EXIT /B 1
)
taskkill /? >NUL
IF %ERRORLEVEL% EQU 9009 (
ECHO No "taskkill"!
EXIT /B 1
)
timeout 0 > NUL
IF %ERRORLEVEL% EQU 9009 (
ECHO No "timeout"!
EXIT /B 1
)

REM === MAIN ===

:main

time /t

tasklist /fi "imagename eq VRChat.exe"|find /i "VRChat.exe" >NUL
IF %ERRORLEVEL% EQU 1 (
ECHO VRChat.exe not running!
GOTO sleep
)

FOR /F "tokens=*" %%L IN ('dir ^"%_VRCPROFILE%\output_log_*.txt^" /s /b /o:d /t:w 2^>NUL') DO SET _LOGFILE=%%L
IF NOT EXIST "%_LOGFILE%" (
ECHO No log!
GOTO sleep
)
FOR %%F in ("%_LOGFILE%") DO echo Using "%%~nxF".

FOR /F "tokens=1 delims=[]" %%M IN ('FIND /n ^"[Behaviour] Disconnected^" ^"%_LOGFILE%^" 2^>NUL') DO SET _DISCO=%%M
IF "%_DISCO:~0,1%" == "-" (
GOTO sleep
)
ECHO Disconnected. Restarting in %_GRACESECS% seconds...
timeout %_GRACESECS% /nobreak >NUL

IF DEFINED %_DESTS% IF "%_DESTS:~18,4%" == "wrld" SET _DESTSBAK=%_DESTS%
IF DEFINED %_DESTS% IF "%_DESTS:~18,4%" == "wrld" SET _DESTIBAK=%_DESTI%

FOR /F "tokens=1,4 delims=[]" %%N IN ('FIND /n ^"[Behaviour] Destination set^" ^"%_LOGFILE%^" 2^>NUL') DO (
SET _DESTI=%%N
SET _DESTS=%%O
)
IF "%_DESTI:~0,1%" == "-" (
ECHO Using previous Destination.
SET _DESTS=NULL
)
IF NOT "%_DESTS:~18,4%" == "wrld" SET _DESTI=%_DESTIBAK%
IF NOT "%_DESTS:~18,4%" == "wrld" SET _DESTS=%_DESTSBAK%
IF %_DISCO% GTR %_DESTI% (
GOTO killvrc
)
ECHO Reconnected? Cancelling restart.

REM == FUNCTIONS ===

:sleep
timeout %_SLEEPSECS% /nobreak >NUL
GOTO main

:killvrc
taskkill /F /IM VRChat.exe

:taskvrc
timeout 3 /nobreak >NUL
tasklist /fi "imagename eq VRChat.exe"|find /i "VRChat.exe" >NUL
IF %ERRORLEVEL% EQU 1 GOTO startvrc
IF %ERRORLEVEL% EQU 0 GOTO taskvrc

:startvrc
ECHO "vrchat://launch?id=%_DESTS:~18%"
IF %_VRCSHORTCUT% EQU 0 (
start "" "vrchat://launch?id=%_DESTS:~18%"
) ELSE (
start "" "%_VRCSHORTCUT%" "vrchat://launch?id=%_DESTS:~18%"
)
GOTO sleep

:exit

pause
