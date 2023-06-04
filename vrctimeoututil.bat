@echo off
REM VRChat Timeout Restart Utility 20230604 @gin_vrc

REM == SETTINGS ===

REM Path to VRChat shortcut (Windows .lnk Shortcut file)
REM **CHANGE THE FOLLOWING LINE**
SET _VRCSHORTCUT=%USERPROFILE%\Desktop\VRChat.lnk

REM Path to VRC Profile directory (no trailing slash)
SET _VRCPROFILE=%USERPROFILE%\AppData\LocalLow\VRChat\VRChat

REM Time in seconds to check for disconnects.
SET _SLEEPSECS=300

REM Delay in seconds before restarting on disconnect.
SET _GRACESECS=60


REM === FIND REQUIREMENTS ===
REM Windows 7+ required

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
REM GOTO startvrc
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

FOR /F "tokens=1 delims=[]" %%N IN ('FIND /n ^"[Behaviour] Destination^" ^"%_LOGFILE%^" 2^>NUL') DO SET _DESTI=%%N
IF "%_DESTI:~0,1%" == "-" (
GOTO killvrc
)
ECHO Reconnected? Cancelling restart.

REM == FUNCTIONS ===

:sleep
timeout %_SLEEPSECS% /nobreak >NUL
goto main

:killvrc
taskkill /F /IM VRChat.exe

:taskvrc
timeout 3 /nobreak
tasklist /fi "imagename eq VRChat.exe"|find /i "VRChat.exe" >NUL
IF %ERRORLEVEL% EQU 1 GOTO startvrc
IF %ERRORLEVEL% EQU 0 GOTO taskvrc

:startvrc
"%_VRCSHORTCUT%"
goto sleep

:exit

pause
