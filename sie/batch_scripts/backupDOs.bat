@echo off
REM #####################################################################
REM ##
REM ## System:       HiPath OpenScape
REM ## Component:    bld
REM ## SubComponent: tools
REM ## Module:
REM ##
REM ## Description:  Batch script to zip all DOs (found in bin/obj dir) files
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  08/04/06  kietl     1 Creation
REM ##  08/23/06  kietl     2 excludes *.pdb files
REM #####################################################################
REM #
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/zipfile} (set ZIPFILE=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN

\xpr_installation\bld\tools\deltaTool\PKZIP25.EXE -add -path -recurse -attributes=-readonly -excl=*.pdb %TMP%\%ZIPFILE%.zip
goto :EOF

:USAGE
echo Usage:  backupDOs /zipfile
goto :EOF
