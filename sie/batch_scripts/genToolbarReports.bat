@echo off
setlocal
REM #####################################################################
REM ##
REM ## System:       HiPath OpenScape
REM ## Component:    bld
REM ## SubComponent: tools
REM ## Module:
REM ##
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  10/20/06  kietl     1 Generates toolbar reports
REM ##  11/02/06  kietl     5 Modified to be able to run without VS2005
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE

call \xperience_tools\cm\batch\buildcfg.bat

REM Global Variables
REM ****************
set "Reports=\\usnwkc0010fsrv\FS20050103\Dev&Test\OC130\Reports_%DATE:/=.%_%TIME::=.%"
set ToolbarLog=Toolbar.log
set ReportsLog=Reports.log

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/bdrive}  (set BLDDRIVE=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Check required switches
REM ***********************
if "%BLDDRIVE%"=="" goto :SWITCHERROR

%BLDDRIVE%:

REM Set environment
REM ***************
call "%VS80COMNTOOLS%\vsvars32.bat"

cd \xperience\client\toolbar && del /q/s /a-r *


REM Toolbar NUnit Report Generator
REM ******************************
cd \xperience\client\toolbar
%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\MSBuild.exe Toolbar.sln /p:Configuration=Release > %ToolbarLog% || goto :BLDERROR

cd \xperience\client\toolbar\Reports
%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\MSBuild.exe Reports.sln /p:Configuration=Release > %ReportsLog% || goto :BLDERROR

cd \xperience\client\toolbar\Reports\bin
call run-reports.bat

cd \xperience\client\toolbar\Reports\bin\output
mkdir "%Reports%"
xcopy /Y/S/I * "%Reports%"
copy \xperience\client\toolbar\%ToolbarLog% "%Reports%"
goto :DONE

:USAGE
echo.
echo Usage:  genToolbarReports /bdrive:s
goto :EOF

:SWITCHERROR
echo.
echo Required switche(s) are missing and/or misspelled
goto :EXITERROR

:EXITERROR
pause

:BLDERROR
mkdir "%Reports%"
copy \xperience\client\toolbar\%ToolbarLog% "%Reports%"
echo **** Build Error ****
pause

:DONE
endlocal
