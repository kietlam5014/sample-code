@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2006, Siemens Communication, Inc.
REM ## All Rights Reserved.
REM ##
REM ## System:       HiPath OpenScape
REM ## Component:    bld
REM ## SubComponent: tools
REM ## Module:
REM ##
REM ## Description:  Batch script to create CD Image structure
REM ## Revision History:
REM ##
REM ##  Date      Author  Ver Description
REM ##
REM ##  01/03/06  kietl     	1 Creation
REM ##  02/28/06  kietl     	4 Added optional langver parameter
REM ##  10/11/06  kietl     	9 Changed BIGMO path
REM ##  10/20/06  kietl    	10 Copy SDK Proxy
REM ##  11/28/06  kietl    	11 Create ServciePack if PATCH=1
REM ##  01/11/07  kietl         12 Added Client Toolbar & leave doc blank
REM ##                             Copy from Latest_OpenScape_docs
REM ##  01/18/07  kietl         13 Copy just the SDK Proxy Installset
REM ##  02/22/07 colleenm   	14 Added needed blank files/changed verison 4 to 8.
REM ##  03/01/07 colleenm   	15 Add SDK Proxy documentation
REM ##  03/02/07 colleenm   	16 Fix typos
REM ##  03/13/07 colleenm	17 Add file for CD number for DEDE and ENGB
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE


REM Get Variables
REM ****************
set PATCH=
call \xperience_tools\cm\batch\buildcfg.bat


:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/version} (set BIND=XPR_%RETV%) & (set VBIND=%RETV%)
if /i {%SWTCH%}=={/patch}   (set PATCH=%RETV%)
if /i {%SWTCH%}=={/langver} (set LANGVER=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Check required switches
REM ***********************
if "%VBIND%"=="" goto :SWITCHERROR



if "%PATCH%"=="" call :OpenScapeInstall
call :OpenScapeUtility

if "%LANGVER%" == "" goto :EOF
call :OpenScapeENGB
call :OpenScapeDEDE
goto :EOF



@rem ************
:OpenScapeInstall
@rem ************
@rem - OpenScapeInstall
@rem    + OpenScape
@rem    + OpenScape MCU
@rem    + OpenScape MC
@rem    + OpenScape TFA
@rem    + OpenScape Media Server
@rem    + OpenScape RD
@rem      autorun.inf
@rem      readme.txt
@rem      Setup.exe
@rem      Setup.ico
@echo.
@echo ********** Creating OpenScapeInstall **********


@rem
@rem Copy required files to root CD
@rem
md %TMP%\CDImage_%VBIND%\OpenScapeInstall
set TD=%TMP%\CDImage_%VBIND%\OpenScapeInstall
echo >%TD%\OpenScapeInstall-2-80-XXXX-00
echo >%TD%\OpenScapeInstall-2-8-XXXX


xcopy /V "\xpr_installation\installation\SiInstall\Build\Tools\CD\SiFileSetup\autorun.inf" %TD%
xcopy /V "\xpr_installation\installation\SiInstall\Build\Tools\CD\SiFileSetup\res\Setup.ico" %TD%
xcopy /V "\xpr_installation\dat\common\readme.txt" %TD%
xcopy /V "\xpr_install_deliver\Output\installation\Setup.exe" %TD%

md %TD%\OpenScape
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape" %TD%\OpenScape

md "%TD%\OpenScape EDM"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape EDM" "%TD%\OpenScape EDM"

md "%TD%\OpenScape MC"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape MC" "%TD%\OpenScape MC"

md "%TD%\OpenScape MCU"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape MCU" "%TD%\OpenScape MCU"

md "%TD%\OpenScape Media Server"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape Media Server" "%TD%\OpenScape Media Server"

md "%TD%\OpenScape RD"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape RD" "%TD%\OpenScape RD"

md "%TD%\OpenScape TFA"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape TFA" "%TD%\OpenScape TFA"

goto :EOF



@rem ************
:OpenScapeUtility
@rem ************
@rem - OpenScapeUtility
@rem      CD Label Template
@rem      Documentation
@rem    + OpenScape Client
@rem    + OpenScape Client Toolbar
@rem    + OpenScape SDK Applications
@rem    + Tools
@rem    + ServicePack
@echo.
@echo ********** Creating OpenScapeUtility **********


md %TMP%\CDImage_%VBIND%\OpenScapeUtility
set TD=%TMP%\CDImage_%VBIND%\OpenScapeUtility

md "%TD%\CD Label Template"
xcopy /V/S "\xpr_installation\CD\CD Label Template" "%TD%\CD Label Template"

md "%TD%\Documentation"

md "%TD%\OpenScape Client"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape Client" "%TD%\OpenScape Client"

md "%TD%\OpenScape Client Toolbar"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape Client Toolbar" "%TD%\OpenScape Client Toolbar"


@rem *** OpenScape SDK Applications ***

md "%TD%\OpenScape SDK Applications\Office Integration\Client"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape Office" "%TD%\OpenScape SDK Applications\Office Integration\Client"

md "%TD%\OpenScape SDK Applications\Office Integration\Client\Documentation"
xcopy /v "\xpr_installation\CD\OpenScape SDK Applications\Office Integration\Client\Documentation" "%TD%\OpenScape SDK Applications\Office Integration\Client\Documentation"

if "%PATCH%"=="" (
  md "%TD%\OpenScape SDK Applications\Office Integration\Server"
  xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape SDK Agent" "%TD%\OpenScape SDK Applications\Office Integration\Server"

  md "%TD%\OpenScape SDK Applications\Office Integration\Server\Documentation"
  xcopy /v "\xpr_installation\CD\OpenScape SDK Applications\Office Integration\Server\Documentation" "%TD%\OpenScape SDK Applications\Office Integration\Server\Documentation"
)

md "%TD%\OpenScape SDK Applications\SDK Proxy\Installset"
xcopy /v/S/Z "\xperience_third_party\OpenScapeSDKProxy\Installset" "%TD%\OpenScape SDK Applications\SDK Proxy\Installset"

md "%TD%\OpenScape SDK Applications\SDK Proxy\Documentation"
xcopy /v/S/Z "\xperience_third_party\OpenScapeSDKProxy\documentation" "%TD%\OpenScape SDK Applications\SDK Proxy\Documentation"

@rem *** Tools ***

md "%TD%\Tools\OpenScape EPT"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OpenScape EPT" "%TD%\Tools\OpenScape EPT"

md "%TD%\Tools\OSCertTool"
xcopy /V/S/Z "%PACKAGES%\v%VBIND%\OSCertTool" "%TD%\Tools\OSCertTool"

md "%TD%\Tools\RTCTool"
xcopy /V/S/Z \xperience_deliver\Output\tools\OpenScapeRTCTool.exe "%TD%\Tools\RTCTool"

md "%TD%\Tools\SOS"
xcopy /V/S/Z \xperience\tools\ServiceTools\SOS "%TD%\Tools\SOS"
rmdir /S/Q "%TD%\Tools\SOS\German-1031"


@rem *** ServicePack ***
if "%PATCH%"=="1" (
  md "%TD%\ServicePack"
  xcopy /V/S/Z "%PACKAGES%\v%VBIND%\ServicePack" "%TD%\ServicePack"
)

set TD=%TMP%\CDImage_%VBIND%\OpenScapeUtility
echo >%TD%\OpenScapeUtility-2-80-XXXX-00
echo >%TD%\OpenScapeUtility-2-8-XXXX

goto :EOF



@rem *********
:OpenScapeENGB
@rem *********
@rem - OpenScapeENGB
@rem    - 3PSW
@rem        InstallTools
@rem      + OSR SpeechReco
@rem        OSRUpgrade
@rem      + Speechify TTS
@rem    + OpenScape
@rem    + OpenScape Media Server
@echo.
@echo ********** Creating OpenScapeENGB **********

@rem NOTE: For now, just do language only. Does not do 3PSW yet
@rem
md %TMP%\CDImage_%VBIND%\OpenScapeENGB
set TD=%TMP%\CDImage_%VBIND%\OpenScapeENGB
echo >%TD%\OpenScapeENGB-2-80-XXXX-00
echo >%TD%\OpenScapeENGB-2-90-XXXX-00
echo >%TD%\OpenScapeENGB-2-8-XXXX

md "%TD%\OpenScape"
xcopy /V/S/Z "%PACKAGES%\Languages\v%LANGVER%\en-GB\OpenScape" "%TD%\OpenScape"

md "%TD%\OpenScape Media Server"
xcopy /V/S/Z "%PACKAGES%\Languages\v%LANGVER%\en-GB\OpenScape Media Server" "%TD%\OpenScape Media Server"


goto :EOF



@rem *********
:OpenScapeDEDE
@rem *********
@rem - OpenScapeDEDE
@rem    - 3PSW
@rem        InstallTools
@rem      + OSR SpeechReco
@rem        OSRUpgrade
@rem      + Speechify TTS
@rem    + OpenScape
@rem    + OpenScape Media Server
@echo.
@echo ********** Creating OpenScapeDEDE **********

@rem NOTE: For now, just do language only. Does not do 3PSW yet
@rem
md %TMP%\CDImage_%VBIND%\OpenScapeDEDE
set TD=%TMP%\CDImage_%VBIND%\OpenScapeDEDE
echo >%TD%\OpenScapeDEDE-2-80-XXXX-00
echo >%TD%\OpenScapeDEDE-2-90-XXXX-00
echo >%TD%\OpenScapeDEDE-2-8-XXXX

md "%TD%\OpenScape"
xcopy /V/S/Z "%PACKAGES%\Languages\v%LANGVER%\de-DE\OpenScape" "%TD%\OpenScape"

md "%TD%\OpenScape Media Server"
xcopy /V/S/Z "%PACKAGES%\Languages\v%LANGVER%\de-DE\OpenScape Media Server" "%TD%\OpenScape Media Server"

goto :EOF




:USAGE
echo.
echo Usage: createCDImageStructure /version:2.00.9200.00 [/langver:2.90.4046.00] [/patch:1]
goto :EOF

:SWITCHERROR
echo.
echo Required switche(s) are missing and/or misspelled
