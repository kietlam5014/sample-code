@echo off
REM #####################################################################
REM ##
REM ## Description:  Unlock and lock labels excluding supplied NUSER
REM ##
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  01/09/06  kietl     1 Creation
REM #####################################################################
REM #

set CT=cleartool
set NUSER="topadm,root"

if not exist "labels.txt" goto :ERROR

@rem Unlocking & locking Lables
@rem
for /f %%I in (labels.txt) do (
  %CT% unlock lbtype:%%I
  %CT% lock -nusers %NUSER% lbtype:%%I
)

goto :EOF

:ERROR
@echo.
@echo labels.txt not exists. Create this file with list of ClearCase labels.
