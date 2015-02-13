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
REM ##  11/08/06  kietl     1 	Creation
REM ##  02/08/07 colleen    9 	Correct labeling error
REM ##  02/08/07 colleen   10   Remove toolbar private directory Properties
REM ##  02/09/07 colleen   11   Add labelig for OptiClient130
REM ## 02/09/07 colleenm 12  Add labeling for CommonFiles
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
call "%VS80COMNTOOLS%\vsvars32.bat"

%BLDDRIVE%:
%CT% catcs | findstr %BIND% || goto :CONFIGERROR

REM Clear all view private files and dirs
REM *************************************
del /Q %TMP%\*.done
cd \xperience_tools && del /q/s /a-r *
cd \xperience && del /q/s /a-r *
cd \xperience\client\toolbar\DeviceListUI && rmdir /q/s Properties

:CONT1
%BLDDRIVE%:

REM Goto build drive, set cache and start the build
REM ***********************************************
cd \xperience\bld
%CT% setcache -view -cachesize 4000000 -cview


:CONT2
if exist %TMP%\os.done goto :CONT3

%CT% lsco -cview toolbar_accumulated.log | findstr checkout >NUL || set STAT2=BEGINNING
omake BIND=%BIND% START_AT=%STAT2% -f toolbar.mak || goto :BLDERROR
if /i "%CI%"=="1" (
   cd \xperience\bld
   @ccperl %CMTOOLS%\checkLogFail.pl tbar && omake BIND=%BIND% loadbuild_done -f toolbar.mak && echo > %TMP%\os.done && echo > %DONESTOR%\%BIND%.done"
   if not exist %TMP%\os.done goto :BLDERROR
)

:CONT3
cd \xperience_tools\bld

%CT% lsco -cview makefile_accumulated.log | findstr checkout >NUL || set STAT3=BEGINNING
omake BIND=%BIND% START_AT=%STAT3% || goto :BLDERROR

if /i "%CI%"=="1" (
   @ccperl %CMTOOLS%\checkLogFail.pl XTOOLS && omake BIND=%BIND% loadbuild_done && echo > %TMP%\xtools.done
   if not exist %TMP%\xtools.done goto :BLDERROR
)


cd %CMTOOLS%
REM 
REM run InstallShield build.  i.e. buildInstall_xpr.bat 2.00.8600.00
REM ****************************************************************
call buildInstall_toolbar.bat /version:%VBIND% /patch:%PATCH%


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
call :LABELSRC \xperience\bld %BIND%
call :LABELSRC \xperience\dat %BIND%
call :LABELSRC \xperience\preprocess %BIND%
call :LABELSRC \xperience\client %BIND%
%CT% mklabel %BIND% \xperience
call :LABELSRC \xperience_deliver %BIND%
%CT% mklabel %BIND% \xperience_deliver
call :LABELSRCS:\xperience_third_party\CommonFiles\MergeModules\InstallShield %BIND%
%CT% mklabel %BIND% \xperience_third_party\CommonFiles\MergeModules
%CT% mklabel %BIND% \xperience_third_party\CommonFiles
call :LABELSRC \xperience_third_party\OpenScapeSDKProxy %BIND%
call :LABELSRC \xperience_third_party\PERL %BIND%
call :LABELSRC \xperience_third_party\Siemens\OptiClient130 %BIND%
%CT% mklabel %BIND% \xperience_third_party\Siemens
%CT% mklabel %BIND% \xperience_third_party
call :LABELSRC \xperience_tools %BIND%
call :LABELSRC \xpr_installation %BIND%
call :LABELSRC \xpr_install_deliver %BIND%
call :LABELSRC \xperience_pkg %BIND%

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
goto :EOF

:LABELSRC
cd %1
%CT% mklabel -rec %2 .
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

:DONE
