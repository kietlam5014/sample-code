@echo off
setlocal
REM #####################################################################
REM ##
REM ## System:       Xperience
REM ##
REM ## Description:  Batch script to build Install Language Packs.
REM ## Revision History:
REM ##
REM ## Date     Author  Ver Description
REM ##
REM ## 10/22/04 kietl     1 Creation
REM ## 02/14/05 kietl     4 Added idrive option
REM ## 05/09/05 kietl     5 Corrected filename in Usage
REM ## 06/16/05 kietl     6 Update first before cd into %CMTOOLS%
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE

call \xperience_tools\cm\batch\buildcfg.bat
if %ERRORLEVEL% EQU 1 goto :EXITERROR

REM Global Variables
REM ----------------
set ALLANGS=1031 2057
set PATCH=

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/version} (set VBIND=%RETV%)
if /i {%SWTCH%}=={/lang}    (set LANG=%RETV%)
if /i {%SWTCH%}=={/idrive}  (set XINSTALLDRV=%RETV%)
if /i {%SWTCH%}=={/patch}   (set PATCH=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Check required switches
REM ***********************
if "%VBIND%"=="" goto :SWITCHERROR
if "%LANG%"=="" set LANG=%ALLANGS%

%XINSTALLDRV%:

%CT% update -overwrite -ptime >NUL

cd %CMTOOLS%
call attr.bat

cd \xpr_installation\bld
del /q makefile_inst

for %%i in (%LANG%) do (
  if not exist %TMP%\%%i.done (
    omake -L BIND=LPK_%VBIND% LANG=%%i PATCH=%PATCH% START_AT=BEGINNING -f lpgenmakefile || goto :EXITERROR
    omake -L BIND=LPK_%VBIND% LANG=%%i PATCH=%PATCH% START_AT=BEGINNING -f langpack || goto :EXITERROR
    omake BIND=LPK_%VBIND% loadbuild_done -f langpack && echo > %TMP%\%%i.done"
    omake BIND=LPK_%VBIND% loadbuild_done -f lpgenmakefile
  )
)

for %%i in (%LANG%) do (
   del /Q %TMP%\%%i.done
)
goto :EOF


:USAGE
echo Usage: buildInstallLang_xpr.bat  /version:1.50.7200.00 [/lang:1031] [/idrive:x] [/patch:1]
echo.
goto :EOF

:SWITCHERROR
echo.
echo Required switche(s) are missing or misspelled
goto :EXITERROR

:EXITERROR
pause

endlocal
