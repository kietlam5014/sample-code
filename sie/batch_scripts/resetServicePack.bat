@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2006, Siemens Communications, Inc.
REM ## All Rights Reserved.
REM ##
REM ## System:       HiPath OpenScape
REM ## Component:    cm
REM ## SubComponent: batch
REM ## Module:
REM ##
REM ## Description:  Batch script to reset Service Pack.
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  03/06/06  kietl     1 Creation
REM #####################################################################
REM #

REM Global Variables
REM ****************
set CT=cleartool
set OSZIP=\xpr_installation\dat\OpenScape.zip


cd \xperience_pkg\mcu\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\xperience\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\xmc\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\comres\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\xprRD\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\xprTFA\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\xprEDM\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\stc\installation\All\ServicePack\Interm
call :COPY_PCPZIP

cd \xperience_pkg\sts\installation\All\ServicePack\Interm
call :COPY_PCPZIP

goto :EOF


REM Reset *.pcp and *.zip files by copying its template
REM ***************************************************
:COPY_PCPZIP
%CT% co -ndata -nc XprXperience.pcp OpenScape.zip
copy @XprXperience.pcp XprXperience.pcp
copy %OSZIP% 
%CT% ci -nc XprXperience.pcp OpenScape.zip
goto :EOF
