@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2000, Siemens Enterprise Networks, Inc.
REM ## All Rights Reserved.
REM ##
REM ## System:       HiPath OpenScape
REM ## Component:    bld
REM ## SubComponent: tools
REM ## Module:
REM ##
REM ## Description:  Batch script to create, label and start the build.
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  --------- xperience_v1.0_sjc -----------------------------------
REM ##  01/21/03  kietl     2 Fixed to get correct windows path
REM ##  02/12/03  kietl     3 Major enhancement
REM ##  02/18/03  kietl     4 Added to trigger e-mailer
REM ##  02/21/03  cheril    5 Added paynec, cheril & kietl to NUSER
REM ##  03/06/03  paynec    8 Add mklabel for iwr_deliver VOB
REM ##  03/07/03  paynec    9 Add mklbtye for iwr_deliver VOB
REM ##  03/07/03  paynec   10 Add comments
REM ##  03/12/03  kietl    11 Added \rulesservice
REM ##  03/21/03  kietl    12 Removed most ism files
REM ##  03/25/03  kietl    13 Added check for previous build
REM ##  03/26/03  kietl    16 Removed code to trigger emailer. Done at postlog
REM ##  -------------- xperience_v1.0_sjc ---------------------------
REM ##  09/15/03  paynec    4 Add label of iwr and iwr_deliver
REM ##  --------- xpr_drop4_sjc -----------------------------------------
REM ##  04/30/03  kietl     1 Clean all private files before start of build
REM ##  05/08/03  kietl     2 Do not try to delete Read-only files
REM ##  07/16/03  kietl     3 Ouput os.done for use with other app such as mcu
REM ##  10/06/03  kietl     5 Start packaging build if OpenScape build succeed
REM ##  10/07/03  kietl     6 Removed iwr.  OpenScape no longer depends on IWR
REM ##  10/22/03  kietl    11 Added config parameter to pdbackup
REM ##  10/23/03  kietl    12 Added EXITERROR and BLDERROR
REM ##-------------------------------------------------------------------
REM ##  11/23/03  kietl     1 Merged
REM ##  01/22/04  kietl     2 Call :BLDERROR instead
REM ##  04/20/04  kietl     4 Direct copy from dbuildstart
REM ##  05/04/04  kietl     5 Build components at xperience_tools
REM ##  05/07/04  kietl     8 Pass XTOOLS parameter to checklogfail
REM ##  05/10/04  kietl     9 call buildcfg from source control instead of c:\
REM ##  06/02/04  cheril   10 removed %MMODULE% parameter
REM ##  06/16/04  kietl    12 Update build view config specs with BIND
REM ##  06/17/04  kietl    13 Create buildlog if not exist
REM ##  06/24/04  kietl    14 Use defined done storage variable
REM ##  07/20/04  kietl    15 Removed -k to wait if VOB lock occurs
REM ##  09/01/04  kietl    16 Enhanced arguments processing
REM ##  09/07/04  kietl    20 Added argument error checking
REM ##  11/02/04  kietl    21 Set default checkin=1 and added cont parameter
REM ##  11/04/04  kietl    24 Check accumulated log and continue the build if
REM ##                        it's checked out.
REM ##  11/11/04  kietl    25 setLGB here
REM ##  11/11/04  kietl    26 Build bc components first & checked in so
REM ##                        Media Server can start saving hours of waiting
REM ##  11/17/04  kietl    29 Stop McShield before the build and Start McShield
REM ##                        after the build or on build error
REM ##  03/08/05  kietl    33 Added time stamp for labeling
REM ##  03/10/05  cheril   34 Changed view cache size to 4M
REM ##  05/12/05  kietl    35 Stored labeltime at %DONESTOR%
REM ##  02/22/06  kietl    38 Failed if build view not found
REM ##  03/28/06  kietl    39 Fail if BIND does not match if config specs
REM ##  07/22/06  kietl    40 Removed start/stop McShield
REM ##  10/13/06  kietl    41 Added report generator to toolbar
REM ##  01/25/07  kietl    46 Mounts all related vobs
REM ##  01/31/07  colleen  47 Fixed script hanging as a result of mounting of VOBS
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE

call \xperience_tools\cm\batch\buildcfg.bat
if %ERRORLEVEL% EQU 1 goto :EXITERROR

REM Global Variables
REM ****************
set LBLEXIST=0
set CONT=0
set CI=1
set STAT1=
set STAT2=
set STAT3=

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/version} (set BIND=XPR_%RETV%) & (set VBIND=%RETV%)
if /i {%SWTCH%}=={/bdrive}  (set BLDDRIVE=%RETV%)
if /i {%SWTCH%}=={/checkin} (set CI=%RETV%)
if /i {%SWTCH%}=={/patch}   (set PATCH=%RETV%)
if /i {%SWTCH%}=={/cont}    (set CONT=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN

REM Mount VOBS
REM xperience_tools VOB must be loaded for this script to start 
REM ***********************************************************
cleartool mount \mcu 2>NUL
cleartool mount \mcu_deliver 2>NUL
cleartool mount \mcu_third_party 2>NUL
cleartool mount \rulesservice 2>NUL
cleartool mount \xperience 2>NUL
cleartool mount \xperience_deliver 2>NUL
cleartool mount \xperience_pkg 2>NUL
cleartool mount \xperience_third_party 2>NUL
cleartool mount \xperience_tools 2>NUL
cleartool mount \xpr_install_deliver 2>NUL
cleartool mount \xpr_installation 2>NUL


REM Check required switches
REM ***********************
if "%BIND%"=="" goto :SWITCHERROR
if "%BLDDRIVE%"=="" goto :SWITCHERROR

REM Skip all initializations and making label
REM and continue the build
REM *****************************************
if "%CONT%"=="1" goto :CONT1

REM Check to not build what is already build
REM ****************************************
cd \xperience
%CT% desc -short lbtype:%BIND% && set LBLEXIST=1
if "%LBLEXIST%"=="1" goto :DONE

REM Update build view config specs with BIND
REM ****************************************
cd %CMTOOLS%
copy /Y xbuild.cs %TMP%
call updateCSbind.bat -bind %VBIND% -file xbuild.cs
ct setcs -tag %XBLDVIEWTAG% %TMP%\xbuild.cs || goto :EXITERROR

REM Make Label Type & Label
REM ***********************
call :MKLABEL
call :LABELVOB


REM Set .NET Environment
REM ********************
if not defined VSINSTALLDIR call %CMTOOLS%\vsvars32.bat

%BLDDRIVE%:
%CT% catcs | findstr %BIND% || goto :CONFIGERROR

REM Clear all view private files and dirs
REM *************************************
del /Q %TMP%\*.done
cd \xperience_tools && del /q/s /a-r *
cd \xperience && del /q/s /a-r *
cd \xperience\client\toolbar\DeviceListUI && rmdir /q/s Properties

REM F52848
REM ******
cd \xpr_installation
%CT% co -nc \xpr_installation\installation\SiInstall\Installer\OpenScape\XprOpenScape.ism
%CT% co -nc \xpr_installation\xperience\installation\SiInstall\Installer\xperience\XprXperience.ism
%CT% co -nc \xpr_installation\xmc\installation\SiInstall\Installer\xperience\XprXperience.ism

:CONT1
%BLDDRIVE%:

REM Goto build drive, set cache and start the build
REM ***********************************************
cd \xperience\bld
%CT% setcache -view -cachesize 4000000 -cview

if exist %TMP%\bc.done goto :CONT2

%CT% lsco -cview bc_accumulated.log | findstr checkout >NUL || set STAT1=BEGINNING
omake BIND=%BIND% START_AT=%STAT1% -f bc.mak || goto :BLDERROR
if /i "%CI%"=="1" (
   cd \xperience\bld
   @ccperl %CMTOOLS%\checkLogFail.pl bc && omake BIND=%BIND% loadbuild_done -f bc.mak && echo > %TMP%\bc.done && echo > %DONESTOR%\bc_%VBIND%.done"
   if not exist %TMP%\bc.done goto :BLDERROR
)

:CONT2
if exist %TMP%\os.done goto :CONT3

%CT% lsco -cview app_accumulated.log | findstr checkout >NUL || set STAT2=BEGINNING
omake BIND=%BIND% START_AT=%STAT2% -f app.mak || goto :BLDERROR
if /i "%CI%"=="1" (
   cd \xperience\bld
   @ccperl %CMTOOLS%\checkLogFail.pl app && omake BIND=%BIND% loadbuild_done -f app.mak && echo > %TMP%\os.done && echo > %DONESTOR%\%BIND%.done"
   if not exist %TMP%\os.done goto :BLDERROR
)

REM Update Last GoodBuild Label
REM ***************************
if exist %TMP%\os.done (
   echo.
   echo Updating Last Good Build Label...
   @ccperl %CMTOOLS%\setLGB.pl %BIND% Release
)

:CONT3
cd \xperience_tools\bld

%CT% lsco -cview makefile_accumulated.log | findstr checkout >NUL || set STAT3=BEGINNING
omake BIND=%BIND% START_AT=%STAT3% || goto :BLDERROR

if /i "%CI%"=="1" (
   @ccperl %CMTOOLS%\checkLogFail.pl XTOOLS && omake BIND=%BIND% loadbuild_done && echo > %TMP%\xtools.done
   if not exist %TMP%\xtools.done goto :BLDERROR
)

cd \xperience
call \xperience\bld\tools\pdbackup -cfg Release -dir \\Ntap02\swtoldev\swprod\pdb\Release\%BIND%

%CT% unco -rm \xpr_installation\installation\SiInstall\Installer\OpenScape\XprOpenScape.ism
%CT% unco -rm \xpr_installation\xperience\installation\SiInstall\Installer\xperience\XprXperience.ism
%CT% unco -rm \xpr_installation\xmc\installation\SiInstall\Installer\xperience\XprXperience.ism

cd %CMTOOLS%
REM 
REM run InstallShield build.  i.e. buildInstall_xpr.bat 2.00.8600.00
REM ****************************************************************
call buildInstall_xpr.bat /version:%VBIND% /patch:%PATCH%


REM Toolbar NUnit Report Generator
REM ******************************
cd \xperience\client\toolbar\bld
omake verbose=1 do=0
cd \xperience\client\toolbar\Reports\bld
omake verbose=1
cd \xperience\client\toolbar\Reports\bin
call run-reports.bat
mkdir \\usnwkc0010fsrv\FS20050103\Dev&Test\OC130\Reports_%VBIND%
xcopy /Y/S/I * \\usnwkc0010fsrv\FS20050103\Dev&Test\OC130\Reports_%VBIND%

pause
goto :DONE


:LABELVOB
time /t > %DONESTOR%\labeltime_%BIND%"
for /d %%i in (\xperience\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xperience
for /d %%i in (\xperience_deliver\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xperience_deliver
for /d %%i in (\xperience_third_party\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xperience_third_party
for /d %%i in (\xperience_tools\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xperience_tools
for /d %%i in (\xpr_installation\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xpr_installation
for /d %%i in (\xpr_install_deliver\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xpr_install_deliver
for /d %%i in (\xperience_pkg\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \xperience_pkg
for /d %%i in (\rulesservice\*) do call :LABELSRC "%%i" %BIND%
%CT% mklabel %BIND% \rulesservice
time /t >> %DONESTOR%\labeltime_%BIND%"
goto :EOF


:MKLABEL
cd \xperience && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_third_party && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_deliver && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_tools && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xpr_installation && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xpr_install_deliver && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_pkg && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \rulesservice && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
goto :EOF

:LABELSRC
cleartool mklabel -rec %2 %1
goto :EOF

:USAGE
echo Usage:  buildstart /version:2.00.9200.00 /bdrive:s [/patch:1] [/cont:1] [/checkin:0]
goto :EOF

:SWITCHERROR
echo.
echo Required switche(s) are missing and/or misspelled
goto :EXITERROR

:CONFIGERROR
echo.
echo %BIND% does not match with config specs
goto :EXITERROR

:BLDERROR
rmdir /Q/S \\ntap02\swtoldev\swprod\buildlog\%BIND%
if not exist \\ntap02\swtoldev\swprod\buildlog mkdir \\ntap02\swtoldev\swprod\buildlog
call \xperience\bld\tools\postlog.bat -build %BIND%
goto :EXITERROR

:EXITERROR
echo.
pause

:DONE
