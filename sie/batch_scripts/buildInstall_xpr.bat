@echo off
REM #####################################################################
REM ##
REM ## System:       Xperience
REM ##
REM ## Description:  Batch script to build Xperience Install Package.
REM ## Revision History:
REM ##
REM ## Date      Author  Ver Description
REM ##
REM ##------------------------ xperience_v1.0_sjc -----------------------
REM ## 02/03/03  kietl     1 Creation
REM ## 10/06/03  kietl     2 Major change
REM ## 10/10/03  kietl     4 Set to bld directory
REM ## 10/10/03  kietl     5 Clear all DOs before packaging
REM ## 10/20/03  kietl     8 Do loadbuild_done if build complete
REM ## 11/03/03  kietl    14 Added exit on error
REM ## 11/11/03  kietl    15 Make sure no checked outs on xpr_installation
REM ##------------------------ xperience_sjc ----------------------------
REM ## 01/16/04  kietl    01 Merged from main latest
REM ## 02/25/04  kietl     2 Set package done state at Bigmo44
REM ## 03/09/04  kietl     3 Add argument for building merge module
REM ## 03/10/04  kietl     4 Set to write attribute for xpr_installation
REM ## 03/10/04  kietl     6 Add check for build error log
REM ## 03/10/04  kietl     7 Call buildcfg if not already call
REM ## 03/18/04  kietl     8 -L Disable config management in snapshot view
REM ## 03/30/04  kietl     9 Do not close screen on error
REM ## 04/19/04  kietl    10 Copy template makefile
REM ## 05/11/04  kietl    13 call buildcfg from source control instead of c:\
REM ## 05/27/04  kietl    15 Add tool to check for correct file version
REM ## 06/15/04  kietl    17 cd into \xpr_installation\bld\tools\deltaTool
REM ##                       before calling MsiFileVer.bat
REM ## 07/21/04  kietl    22 Set attribute to -R for all VOBs
REM ## 07/27/04  kietl    24 Do not set attribute for state and logs
REM ## 08/26/04  kietl    26 Build genmakefile to generate makefile_inst
REM ## 09/01/04  kietl    29 Enhanced arguments processing
REM ## 11/17/04  kietl    32 Stop/start McShield during/after the build
REM ## 11/19/04  kietl    33 Check for error after loadbuild_done
REM ## 09/20/05  kietl    36 G52033: Reset InstallShield X MMSearchPath
REM ## 07/22/06  kietl    40 Removed start/stop McShield
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE

call \xperience_tools\cm\batch\buildcfg.bat
if %ERRORLEVEL% EQU 1 goto :EXITERROR

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/version} (set VBIND=%RETV%)
if /i {%SWTCH%}=={/patch}   (set PATCH=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Mount snapshot view to drive letter
REM -----------------------------------
subst %XINSTALLDRV%: /D >NUL
subst %XINSTALLDRV%: %SXVIEW%

%XPR_LABELDRV%:
cd %CMTOOLS%
copy /Y xinstall.cs %TMP%
call %CMTOOLS%\updateCSbind.bat -bind %VBIND% -file xinstall.cs

%XINSTALLDRV%:
%CT% setcs %TMP%\xinstall.cs >NUL

cd \xperience_pkg && del /q/s /a-r *
cd \xpr_installation && del /q/s /a-r *
ccperl %CMTOOLS%\unco.pl


%CT% update -overwrite -ptime >NUL

REM F86502
REM ------
cd \rulesservice && attrib -R *.* /S
cd \xperience && attrib -R *.* /S
cd \xperience_tools && attrib -R *.* /S
cd \xperience_deliver && attrib -R *.* /S
cd \xperience_third_party && attrib -R *.* /S
cd \xpr_install_deliver && attrib -R *.* /S
cd \xpr_installation && attrib -R *.* /S
cd \xpr_installation\bld
attrib +R *.state
attrib +R *.log

cd \xpr_installation\bld
copy /Y makefile_inst.template makefile_inst

omake -L BIND=XPR_%VBIND% PATCH=%PATCH% START_AT=BEGINNING -f genmakefile || goto :EXITERROR

@rem reset InstallShield X MMSearchPath
regedit.exe /s \xperience_third_party\CommonFiles\MergeModules\InstallShield\ISPath.reg

omake -L BIND=XPR_%VBIND% PATCH=%PATCH% START_AT=BEGINNING || goto :EXITERROR
@ccperl %CMTOOLS%\checkLogFail.pl IXPR && omake BIND=XPR_%VBIND% loadbuild_done && echo > %TMP%\xpkg.done && echo > %DONESTOR%\xpkg_%VBIND%.done"
omake BIND=XPR_%VBIND% loadbuild_done -f genmakefile

if not exist %TMP%\xpkg.done (
   echo.
   echo There are errors during Loadbuild_done
   goto :EXITERROR
)

@rem check & output file version
if "%PATCH%"=="" (
  cd \xpr_installation\bld\tools\deltaTool
  call \xpr_installation\bld\tools\deltaTool\MsiFileVer.bat %VBIND% OpenScape
  echo. && type %TMP%\StFileVer.txt
)
goto :EOF

:USAGE
echo Usage:   buildInstall_xpr  /version:1.50.7200.00 [/patch:1]
echo.
goto :EOF

:EXITERROR
echo.
pause
