@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2004, Siemens Enterprise Networks, Inc.
REM ## All Rights Reserved.
REM ##
REM ## System:       OpenScape
REM ## Component:    cm
REM ## SubComponent: batch
REM ## Module:
REM ##
REM ## Description:  Batch script to build Language Packs for OpenScape
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  10/01/04  kietl     1 Creation
REM ##  10/05/04  kietl     2 Add support to build all languages if
REM ##                        LANG is not supplied.
REM ##  11/02/04  kietl     9 Set default to checkin=1 as default
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE

call \xperience_tools\cm\batch\buildcfg.bat
if %ERRORLEVEL% EQU 1 goto :EXITERROR

REM Global Variables
REM ****************
set ALLANGS=1031 2057
set LBLEXIST=
set CI=1

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/version} (set BIND=LPK_%RETV%) & (set VBIND=%RETV%)
if /i {%SWTCH%}=={/lang}    (set LANG=%RETV%)
if /i {%SWTCH%}=={/bdrive}  (set BLDDRIVE=%RETV%)
if /i {%SWTCH%}=={/checkin} (set CI=%RETV%)
if /i {%SWTCH%}=={/patch}   (set PATCH=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Check required switches
REM ***********************
if "%BIND%"=="" goto :SWITCHERROR
if "%LANG%"=="" set LANG=%ALLANGS%
if "%BLDDRIVE%"=="" goto :SWITCHERROR

REM Check to not build what is already build
REM ****************************************
cd \xperience
%CT% desc -short lbtype:%BIND% && set LBLEXIST=1
if "%LBLEXIST%"=="1" echo **** Warning: This label already exists ****

REM Make Label Type & Label
REM ***********************
if not defined LBLEXIST call :MKLBTYPE

REM Set .NET Environment
REM ********************
if not defined VSINSTALLDIR call %CMTOOLS%\vsvars32.bat
%BLDDRIVE%:

REM Goto build drive, set cache and start the build
REM ***********************************************
cd \xperience\bld
%CT% setcache -view -cachesize 3145728 -cview

for %%i in (%LANG%) do (
   if not exist %TMP%\%%i.done (
      omake BIND=%BIND% LANG=%%i START_AT=BEGINNING -f langpack || goto :BLDERROR
      if /i "%CI%"=="1" @ccperl %CMTOOLS%\checkLogFail.pl LPK && omake BIND=%BIND% loadbuild_done -f langpack && echo > %TMP%\%%i.done
      if not exist %TMP%\%%i.done goto :BLDERROR
   )
)

for %%i in (%LANG%) do (
   del /Q %TMP%\%%i.done
)
goto :DONE

:MKLBTYPE
for %%i in (xperience xperience_deliver xpr_installation xperience_pkg) do (
   cd \%%i
   %CT% desc -short lbtype:%BIND% >NUL || (%CT% mklbtype -nc %BIND% & %CT% lock -nusers %NUSER% lbtype:%BIND%)
)
goto :DONE

:USAGE
echo Usage:  buildlang_xpr /version:2.90.1012.00 [/lang:1031] /bdrive:s [/patch:1] [/checkin:0]
goto :DONE

:SWITCHERROR
echo.
echo Required switche(s) are missing or misspelled
goto :EXITERROR

:BLDERROR
goto :EXITERROR

:EXITERROR
pause

:DONE
