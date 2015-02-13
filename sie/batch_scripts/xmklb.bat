@echo off
REM #####################################################################
REM ## Description:  Batch script to create lable type for all VOBs
REM ##               of OpenScape
REM ##
REM ## Revision History:
REM ##
REM ##  Date        Author  Ver Description
REM ##
REM ##  07/31/03  kietl     2   Creation
REM #####################################################################
REM #
@echo off
color 1a
if %1.==. goto USAGE

REM Global Variables
REM ****************
set CMTOOLS=\xperience_tools\cm\batch
set CT=cleartool
set NUSER="paynec,cheril,kietl,root,topadm"
set LBLEXIST=0

REM Get Arguments
REM *************
set BIND=%1
set BLDDRIVE=%2
set CI=%3

REM Check to not build what is already build
REM ****************************************
%CT% desc -short lbtype:%BIND% && set LBLEXIST=1
if "%LBLEXIST%"=="1" goto :EOF


REM Make Label Type & Label
REM ***********************
call :MKLABEL
goto DONE

:MKLABEL
cd \xperience && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_third_party && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_deliver && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_tools && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xpr_installation && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xpr_install_deliver && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \xperience_pkg && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
cd \rulesservice && %CT% mklbtype -ord -nc %BIND% && %CT% lock -nusers %NUSER% lbtype:%BIND%
goto DONE

:LABELSRC
if not "%~n1"=="lost+found" cleartool mklabel -rec %2 %1
goto DONE

:USAGE
echo Usage:  xmlb BIND

:DONE
