@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2000, Siemens Enterprise Networks, Inc.
REM ## All Rights Reserved.
REM ##
REM ## System:       HiPath 5000
REM ## Component:    bld
REM ## SubComponent: tools
REM ## Module:
REM ##
REM ## Description:  Batch script to label all VOBs
REM ## Revision History:
REM ##
REM ##  Date        Author  Ver Description
REM ##  08/14/2001  kietl     1 Creation
REM ##  09/10/2001  kietl       Added -rep for VOBs too
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE

R:

REM label source
for /d %%i in (\top\*) do call :LABELSRC "%%i" %1
cleartool mklabel -rep %1 \top
for /d %%i in (\top_third_party\*) do call :LABELSRC "%%i" %1
cleartool mklabel -rep %1 \top_third_party
REM for /d %%i in (\smartcom_rel\*) do call :LABELSRC "%%i" %1
REM cleartool mklabel -rep %1 \smartcom_rel
REM for /d %%i in (\top_supp_services\*) do call :LABELSRC "%%i" %1
REM cleartool mklabel -rep %1 \top_supp_services
goto DONE

:LABELSRC
if not "%~n1"=="lost+found" cleartool mklabel -rec -rep %2 %1
goto DONE

:USAGE
echo Usage:  label CCLABEL

:DONE
