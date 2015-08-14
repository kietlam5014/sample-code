@echo off
REM #####################################################################
REM ##
REM ## Author: Kiet Lam (10101482)
REM ## Date: 2009
REM ## System:       Vulcan
REM ## Component:    script tool
REM ## Module:
REM ##
REM ## Description:  Batch script to generate sdr image
REM ## Revision History:
REM ##
REM ##  Date      Author   Description
REM ##
REM ##  09/06/10  10101482 Fixed to get correct windows path
REM ##  09/06/17  10101482 Added operator-lang parameter
REM ##  09/06/19  10101482 Added option to generate dev/prod 
REM ##  09/06/26  10101482 Copy cabs to ConvergenceSW and added error check
REM ##  09/06/30  10101482 Updated to build language
REM ##  09/07/01  10101482 added spaceid in sdr filename
REM ##  09/07/06  10101482 Improved to copy DIO once to Image dir
REM ##  09/07/07  10101482 Added more langs support
REM ##  09/07/13  10101482 Merged cabs from diff dirs to CUSTAPPS
REM ##  09/07/19  10101482 Fixed to copy correct path for dev build and
REM ##                     generated correct space id sdr filename
REM ##  09/07/21  10101482 Added support for Chinese and fixed generic SDR filename
REM ##  09/07/22  10101482 Removed hardcoded drive. Added check if building customization that
REM ##                     custcabs should not be emptied.
REM ##  09/07/26  10101482 Added support to allow user enter language in full word and
REM ##                     not to copy custcabs if operator is not supplied.
REM ##  09/07/27  10101482 Added spaceid for generic langs
REM ##  09/08/05  10101482 Updated to copy specified DIO files
REM ##  09/08/06  10101482 Get installed Perl path
REM ##  09/08/10  10101482 Added /bsp and /bspflat parameters
REM ##  09/08/12  10101482 Added support for more languages
REM ##  09/08/25  10101482 Copy mbn files only
REM ##  09/08/26  10101482 Updated to build DEV_EVAL
REM ##  09/08/27  10101482 Added optional to not build customization CDR
REM ##  09/08/31  10101482 Added support to sign cabs
REM ##  09/09/02  10101482 Added support to build either dev or dev_eval
REM ##  09/09/04  10101482 Fail if it sees that perl is not installed
REM ##  09/09/10  10101482 Copy generic UK to root dir of Prod
REM ##  09/09/11  10101482 No need to supply VIEW as param
REM ##  09/09/23  10101482 Removed ENGRCABS (never been used)
REM ##  09/10/01  10101766 Check perl from other reg location
REM ##  09/10/07  10101482 Failed if there's sign error
REM ##  09/10/08  10101482 Replace space w/ - in filename (done here instead)
REM ##  09/10/11  10101482 Added country: Global generic
REM ##  09/10/15  10101482 Include CDF label to SDR filename
REM ##  09/10/28  10101482 Use generateXML from VOB
REM #####################################################################
REM #
color 1a
setlocal & pushd

if %1.==. goto USAGE
if /i {%1}=={/help} goto :USAGE
if /i {%1}=={/?} goto :USAGE


REM Global Variables
REM ****************
REM set WM650SCRIPTS=\\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW\WM650\BuildScripts\qcmsm
set WM650SCRIPTS=%HOMEDRIVE%\WM650\BuildScripts\qcmsm
set BASEOSENV=SEBaseOSEnv.bat
set BSPFLAT=\\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW\BSP_FLAT
set CONVERGENCE_SW=\\corpusers.net\ussv\ConvergenceSW\Vulcan
set BSPPROD=%CONVERGENCE_SW%\BSP
set BLDSWPROD=%CONVERGENCE_SW%\BuiltSW\Product
set BUILDROOT=%HOMEDRIVE%\Temp\builtsw
set BLD_SDRIMG=%BUILDROOT%\sdr\Images
set CABS=%BUILDROOT%\CABS
set CUSTCABS=%BUILDROOT%\CUSTCABS
set CUSTAPPS=%BUILDROOT%\CUSTAPPS\AUTOEXEC
set LANGCABS=%BUILDROOT%\LANGCABS
set CONFIG=prod
set OPERATOR=CUS
set LANG=UK
set SPACEID=0000-0000
set SIGN=0

:: Get installed Perl path - ex: C:\Perl\bin\perl.exe
for /f "tokens=3" %%i in ('reg query HKLM\Software\perl /v BinDir') do set PERL=%%i

if not defined PERL (
   for /f "tokens=3" %%i in ('reg query HKLM\Software\Wow6432Node\perl /v BinDir') do set PERL=%%i
)

if not defined PERL (echo Stop: Required Perl is missing on this machine!) & (goto :BLDERROR)

:NEXT_ARG
if {%1}=={} goto :MAIN
call :PROCESS_ARG %1
shift /1
goto :NEXT_ARG

:PROCESS_ARG
call :GETSWITCH %1
if /i {%SWTCH%}=={/country} (set COUNTRY=%RETV%)
if /i {%SWTCH%}=={/bsplb}   (set BSPLB=%RETV%)
if /i {%SWTCH%}=={/prodlb}  (set PRODLB=%RETV%)
if /i {%SWTCH%}=={/cabdir}  (set CABDIR=%RETV%)
if /i {%SWTCH%}=={/opr}     (set OPERATOR=%RETV%)
if /i {%SWTCH%}=={/lang}    (set LANG=%RETV%)
if /i {%SWTCH%}=={/config}  (set CONFIG=%RETV%)
if /i {%SWTCH%}=={/bsp}     (set uBSPPROD=%RETV%)
if /i {%SWTCH%}=={/bspflat} (set uBSPFLAT=%RETV%)
if /i {%SWTCH%}=={/nocust}  (set NOCUST=%RETV%)
if /i {%SWTCH%}=={/sign}    (set SIGN=%RETV%)
goto :EOF

:GETSWITCH
(set RET=) & (set RETV=)
for /f "delims=: tokens=1*" %%I in ("%1") do (set SWTCH=%%I) & (set RETV=%%J)
goto :EOF


:MAIN
REM Get VIEW name
REM *************
for /f %%I in ('cleartool pwv -short') do @set VIEW=Z:\%%I
if "%VIEW%"=="NONE" (echo Error: Script must run from a view) & (goto :BLDERROR)

REM Check required switches
REM ***********************
if not defined uBSPFLAT if "%BSPLB%"==""  goto :SWITCHERROR
if "%PRODLB%"=="" goto :SWITCHERROR

if defined uBSPPROD if defined uBSPFLAT goto :M1
if defined uBSPPROD if not defined uBSPFLAT (echo Error: /bspflat require) & (goto :BLDERROR)
if defined uBSPFLAT if not defined uBSPPROD (echo Error: /bsp require) & (goto :BLDERROR)

if not defined uBSPROD   set BSPPROD=%CONVERGENCE_SW%\BSP
if not defined uBSPFLAT  set BSPFLAT=\\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW\BSP_FLAT

:M1

%HOMEDRIVE%

REM echo.
REM echo Mounting P:\\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW
REM subst P: /D >NUL
REM subst P: \\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW

REM Set WM650 Environment
REM *********************
set BLD_BSPPROD=%BUILDROOT%\bsp\rel\%CONFIG%
if not exist %WM650SCRIPTS%\%BASEOSENV% echo Error: %BASEOSENV% not found && goto :BLDERROR
echo.
echo Setting WM650 environment...
if not defined _WINCEROOT call %WM650SCRIPTS%\%BASEOSENV%
set _FLATRELEASEDIR=%BLD_SDRIMG%

REM Get CDF label
for /f %%i in (%CUSTCABS%\custlb) do set CDFLB=%%i

REM user entered two chars language
if /i "%LANG%"=="uk" (set LANG=UK) & (set SLANG=English) & (goto :M2)
if /i "%LANG%"=="ct" (set LANG=UK) & (set SLANG=English) & (goto :M2)
if /i "%LANG%"=="fr" (set LANG=FR) & (set SLANG=French) & (goto :M2)
if /i "%LANG%"=="de" (set LANG=DE) & (set SLANG=German) & (goto :M2)
if /i "%LANG%"=="es" (set LANG=ES) & (set SLANG=Spanish) & (goto :M2)
if /i "%LANG%"=="se" (set LANG=SE) & (set SLANG=Swedish) & (goto :M2)
if /i "%LANG%"=="pb" (set LANG=PB) & (set SLANG=Brazilian_Portuguese) & (goto :M2)
if /i "%LANG%"=="pt" (set LANG=PT) & (set SLANG=Portuguese) & (goto :M2)
if /i "%LANG%"=="cs" (set LANG=CS) & (set SLANG=Czech) & (goto :M2)
if /i "%LANG%"=="da" (set LANG=DA) & (set SLANG=Danish) & (goto :M2)
if /i "%LANG%"=="nl" (set LANG=NL) & (set SLANG=Dutch) & (goto :M2)
if /i "%LANG%"=="en" (set LANG=EN) & (set SLANG=English) & (goto :M2)
if /i "%LANG%"=="fi" (set LANG=FI) & (set SLANG=Finnish) & (goto :M2)
if /i "%LANG%"=="el" (set LANG=EL) & (set SLANG=Greek) & (goto :M2)
if /i "%LANG%"=="it" (set LANG=IT) & (set SLANG=Italian) & (goto :M2)
if /i "%LANG%"=="ja" (set LANG=JA) & (set SLANG=Japanese) & (goto :M2)
if /i "%LANG%"=="ko" (set LANG=KO) & (set SLANG=Korean) & (goto :M2)
if /i "%LANG%"=="no" (set LANG=NO) & (set SLANG=Norwegian) & (goto :M2)
if /i "%LANG%"=="pl" (set LANG=PL) & (set SLANG=Polish) & (goto :M2)
if /i "%LANG%"=="ru" (set LANG=RU) & (set SLANG=Russian) & (goto :M2)
if /i "%LANG%"=="zs" (set LANG=ZS) & (set SLANG=Chinese_Simplified) & (goto :M2)
if /i "%LANG%"=="zh" (set LANG=ZH) & (set SLANG=Chinese_Traditional) & (goto :M2)
if /i "%LANG%"=="zt" (set LANG=ZT) & (set SLANG=Chinese_Traditional) & (goto :M2)

REM user entered full word language
if /i "%LANG%"=="English" (set LANG=UK) & (set SLANG=English) & (goto :M2)
if /i "%LANG%"=="French"  (set LANG=FR) & (set SLANG=French) & (goto :M2)
if /i "%LANG%"=="German"  (set LANG=DE) & (set SLANG=German) & (goto :M2)
if /i "%LANG%"=="Spanish" (set LANG=ES) & (set SLANG=Spanish) & (goto :M2)
if /i "%LANG%"=="Swedish" (set LANG=SE) & (set SLANG=Swedish) & (goto :M2)
if /i "%LANG%"=="Brazilian_Portuguese" (set LANG=PB) & (set SLANG=Brazilian_Portuguese) & (goto :M2)
if /i "%LANG%"=="Portuguese" (set LANG=PT) & (set SLANG=Portuguese) & (goto :M2)
if /i "%LANG%"=="Czech"   (set LANG=CS) & (set SLANG=Czech) & (goto :M2)
if /i "%LANG%"=="Danish"  (set LANG=DA) & (set SLANG=Danish) & (goto :M2)
if /i "%LANG%"=="Dutch"   (set LANG=NL) & (set SLANG=Dutch) & (goto :M2)
if /i "%LANG%"=="Finnish" (set LANG=FI) & (set SLANG=Finnish) & (goto :M2)
if /i "%LANG%"=="Greek"   (set LANG=EL) & (set SLANG=Greek) & (goto :M2)
if /i "%LANG%"=="Italian" (set LANG=IT) & (set SLANG=Italian) & (goto :M2)
if /i "%LANG%"=="Japanese" (set LANG=JA) & (set SLANG=Japanese) & (goto :M2)
if /i "%LANG%"=="Korean"  (set LANG=KO) & (set SLANG=Korean) & (goto :M2)
if /i "%LANG%"=="Norwegian" (set LANG=NO) & (set SLANG=Norwegian) & (goto :M2)
if /i "%LANG%"=="Polish"  (set LANG=PL) & (set SLANG=Polish) & (goto :M2)
if /i "%LANG%"=="Russian" (set LANG=RU) & (set SLANG=Russian) & (goto :M2)
if /i "%LANG%"=="Chinese_Simplified" (set LANG=ZS) & (set SLANG=Chinese_Simplified) & (goto :M2)
if /i "%LANG%"=="Chinese_Traditional" (set LANG=ZH) & (set SLANG=Chinese_Traditional) & (goto :M2)

echo.
echo *** Error: Language %LANG% does not exist ***
goto :BLDERROR

:M2
set CONVERGENCE_TOOLS=%VIEW%\USSV_Devtools\cnh1012571_convergence_tools\Scripts
set NOSPACE=%CONVERGENCE_TOOLS%\nospace.pl
set BLDSCRIPTS=\\corpusers.net\ussv\ConvergenceSW\Vulcan\BuiltSW\Tools
set OPRLANG=GENERIC_%LANG%

if "%NOCUST%"=="1" goto :N3

if /i "%COUNTRY%"=="Australia" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7619) & (set OPRLANG=GENERIC_AU) ) & (goto :N3)
    if /i "%OPERATOR%"=="opt" ( if /i "%LANG%"=="EN" (set SPACEID=1231-0540) & (set OPRLANG=OPTUS_AU) ) & (goto :N3)
    )
  

if /i "%COUNTRY%"=="Austria" (
    if /i "%OPERATOR%"=="mob" ( if /i "%LANG%"=="DE" (set SPACEID=1230-7141) & (set OPRLANG=MOBILKOM_AT) ) & (goto :N3)
       )


if /i "%COUNTRY%"=="Baltics" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7144) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Belgium" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="FR" (set SPACEID=1230-7156) & (set OPRLANG=GENERIC_BE)  & (goto :N3)
    			        if /i "%LANG%"=="NL" (set SPACEID=1230-7155) & (set OPRLANG=GENERIC_BE) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="China" (
    if /i "%OPERATOR%"=="cus" (
        if /i "%LANG%"=="ZS" (set SPACEID=1230-2795) & (set OPRLANG=GENERIC_CN) & (goto :N3)
        if /i "%LANG%"=="EN" (set SPACEID=1234-2554) & (set OPRLANG=GENERIC_CN) & (goto :N3)
    )
)

if /i "%COUNTRY%"=="Czech" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="CS" (set SPACEID=1230-7152) & (set OPRLANG=GENERIC_CZ) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Denmark" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="DA" (set SPACEID=1230-7140) & (set OPRLANG=GENERIC_DK) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Finland" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="FI" (set SPACEID=1230-7151) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="France" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="FR" (set SPACEID=1230-2804) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Germany" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="DE" (set SPACEID=1230-2800) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="DE" (set SPACEID=1230-2396) & (set OPRLANG=VODAFONE_%LANG%) ) & (goto :N3)
      )
      
if /i "%COUNTRY%"=="Global" (
    if /i "%OPERATOR%"=="cus" (
        if /i "%LANG%"=="EN" (
            set SPACEID=1233-7729
            set OPRLANG=GENERIC_INT
        )
        goto :N3
    )
)

if /i "%COUNTRY%"=="Global" (
    if /i "%OPERATOR%"=="cus" (
        if /i "%LANG%"=="EN" (
            set SPACEID=1233-7729
            set OPRLANG=GENERIC_INT
        )
        goto :N3
    )
)


if /i "%COUNTRY%"=="Greece" (
        if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="EL" (set SPACEID=1230-7135) & (set OPRLANG=VODAFONE_GR) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Hong_Kong" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7158) & (set OPRLANG=GENERIC_HK) 
      				    if /i "%LANG%"=="ZH" (set SPACEID=1230-7161) & (set OPRLANG=GENERIC_HK) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Hungary" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7153) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Italy" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="IT" (set SPACEID=1230-7136) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
        if /i "%OPERATOR%"=="win" ( if /i "%LANG%"=="IT" (set SPACEID=1231-4390) & (set OPRLANG=WIND_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="India" (
       if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7157) & (set OPRLANG=GENERIC_IN) ) & (goto :N3)
     )


if /i "%COUNTRY%"=="MENA" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-7134) & (set OPRLANG=MENAL_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="iam" ( if /i "%LANG%"=="FR" (set SPACEID=1230-7154) & (set OPRLANG=IAM_MA) ) & (goto :N3)
    if /i "%OPERATOR%"=="med" ( if /i "%LANG%"=="FR" (set SPACEID=1230-7577) & (set OPRLANG=MEDITEL_MA) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Netherlands" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="NL" (set SPACEID=1230-7137) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="tmo" ( if /i "%LANG%"=="NL" (set SPACEID=1230-7580) & (set OPRLANG=TMOBILE_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="NL" (set SPACEID=1230-2395) & (set OPRLANG=VODAFONE_%LANG%) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Norway" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="NO" (set SPACEID=1230-7138) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Poland" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="PL" (set SPACEID=1230-7146) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Portugal" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="PT" (set SPACEID=1231-4395) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="PT" (set SPACEID=1230-7143) & (set OPRLANG=VODAFONE_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Russia" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="RU" (set SPACEID=1230-6133) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="Singapore" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1231-7617) & (set OPRLANG=GENERIC_SG) ) & (goto :N3)
      )



if /i "%COUNTRY%"=="Spain" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="ES" (set SPACEID=1230-7142) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="mov" ( if /i "%LANG%"=="ES" (set SPACEID=1230-7583) & (set OPRLANG=TELEFONICA_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="ES" (set SPACEID=1230-2394) & (set OPRLANG=VODAFONE_%LANG%) ) & (goto :N3)
      )



if /i "%COUNTRY%"=="Sweden" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="SE" (set SPACEID=1230-2397) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
    if /i "%OPERATOR%"=="tel" ( if /i "%LANG%"=="SE" (set SPACEID=1231-0543) & (set OPRLANG=TELENOR_%LANG%) ) & (goto :N3)
     )


if /i "%COUNTRY%"=="Switzerland" (
    if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="DE" (set SPACEID=1231-4388) & (set OPRLANG=GENERIC_CH) ) & (goto :N3)
    if /i "%OPERATOR%"=="swi" ( if /i "%LANG%"=="EN" (set SPACEID=1231-4392) & (set OPRLANG=SWISSCOM_CH)
 				if /i "%LANG%"=="DE" (set SPACEID=1230-2805) & (set OPRLANG=SWISSCOM_CH)
                                if /i "%LANG%"=="FR" (set SPACEID=1230-2801) & (set OPRLANG=SWISSCOM_CH)
    			        if /i "%LANG%"=="IT" (set SPACEID=1231-4391) & (set OPRLANG=SWISSCOM_CH) ) & (goto :N3)
    if /i "%OPERATOR%"=="sun" ( if /i "%LANG%"=="DE" (set SPACEID=1230-2802) & (set OPRLANG=SUNRISE_CH) ) & (goto :N3)
     )


if /i "%COUNTRY%"=="Taiwan" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="ZT" (set SPACEID=1230-7149) & (set OPRLANG=GENERIC_TW) ) & (goto :N3)
      )


if /i "%COUNTRY%"=="United_Kingdom" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="EN" (set SPACEID=1230-2799) & (set OPRLANG=GENERIC_UK) ) & (goto :N3)
        if /i "%OPERATOR%"=="vod" ( if /i "%LANG%"=="EN" (set SPACEID=1230-2393) & (set OPRLANG=VODAFONE_UK) ) & (goto :N3)
      )

if /i "%COUNTRY%"=="Japan" (
        if /i "%OPERATOR%"=="cus" ( if /i "%LANG%"=="JA" (set SPACEID=1230-4389) & (set OPRLANG=GENERIC_%LANG%) ) & (goto :N3)
      )
  

:N3
Z:
if "%SIGN%"=="1" set SDRFILE=APP-SW_VULCAN_%OPRLANG%_%SPACEID%_%PRODLB%-%CDFLB%__SIGNED.sdr
if "%SIGN%"=="0" set SDRFILE=APP-SW_VULCAN_%OPRLANG%_%SPACEID%_%PRODLB%-%CDFLB%__UNSIGNED.sdr

cd %CONVERGENCE_TOOLS%\SEUS_VersionInfo
call Build.bat /prodlb:%PRODLB% /spaceid:%SPACEID%
copy /v SEUS_VersionInfo.cab %CABS%\zzzzSEUS_VersionInfo%OPERATOR%%LANG%.cab

%HOMEDRIVE%

if /i "%CONFIG%"=="dev" (
   set CONFIG=DEV
   set SLANG=DEV
   set SDRFILE=APP-SW_VULCAN_%OPRLANG%_%PRODLB%_DEV_UNSIGNED.sdr
) else (
   if /i "%CONFIG%"=="dev_eval" (
      set CONFIG=DEV_EVAL
      set SLANG=DEV_EVAL
      set SDRFILE=APP-SW_VULCAN_%OPRLANG%_%PRODLB%_DEV_EVAL_UNSIGNED.sdr   
   )
)

REM Create clean build directories
REM ******************************
if exist %BLD_SDRIMG% del /q %BLD_SDRIMG%\*
if not exist %BLD_SDRIMG% (
   mkdir %BLD_SDRIMG%
   mkdir %BLD_SDRIMG%\MBN
)
if not exist %BLD_SDRIMG%\%SLANG% mkdir %BLD_SDRIMG%\%SLANG%


REM Make sure directories exist
REM ***************************
if defined uBSPFLAT (
   if not exist "%uBSPFLAT%" (echo Error: %uBSPFLAT% does not exist) & (goto :BLDERROR)
) else (
   if not exist %BSPFLAT%\BSP_%BSPLB%_flatrelease\%SLANG% (
      echo Error: %BSPFLAT%\BSP_%BSPLB%_flatrelease\%SLANG% does not exist
      goto :BLDERROR
   )
)

REM Merge all cabs to AUTOEXEC directory (CUSTAPPS)
REM ***********************************************
echo.
echo Merging all cabs to %CUSTAPPS%...
if exist %CUSTAPPS% del /q %CUSTAPPS%
if not exist %CUSTAPPS% mkdir %CUSTAPPS%
if not exist %CUSTAPPS%\Common mkdir %CUSTAPPS%\Common
if not exist %CUSTAPPS%\Offlist mkdir %CUSTAPPS%\Offlist
xcopy /Q/Y/V %CABS% %CUSTAPPS%
xcopy /Q/Y/V %CUSTCABS% %CUSTAPPS%

rem copy unsigned version when building dev or dev_eval
if /i "%CONFIG%"=="dev" (
   del /q %CUSTAPPS%\Common\*
   xcopy /Q/Y/V %CABS%\Common %CUSTAPPS%\Common
) else if /i "%CONFIG%"=="dev_eval" (
   del /q %CUSTAPPS%\Common\*
   xcopy /Q/Y/V %CABS%\Common %CUSTAPPS%\Common
)

if not exist %CUSTAPPS%\Common\cm_%PRODLB% (
   del /q %CUSTAPPS%\Common\*
   xcopy /Q/Y/V %CABS%\Common %CUSTAPPS%\Common
)

if not exist %CUSTAPPS%\Offlist\cm_%PRODLB% (
   del /q %CUSTAPPS%\Offlist\*
   xcopy /Q/Y/V %CABS%\Offlist %CUSTAPPS%\Offlist
)

echo.
echo Removing any spaces from filename
call %PERL% %NOSPACE% %CUSTAPPS%

if "%NOCUST%"=="1" goto :M3
if /i not "%OPERATOR%"=="cus" (
   for /f %%n in ('dir /b /a-d %CUSTCABS%') do set EMPTY=false & goto :M3
   echo.
   echo Stop. Missing cabs in %CUSTCABS% to build customization for %OPERATOR%
   goto :EOF
)

:M3

REM Sign cabs
REM *********
echo.
if "%SIGN%"=="1" (
   Z: && cd %CONVERGENCE_TOOLS%
   if not exist %CUSTAPPS%\Common\cm_signed (
       call %PERL% %CONVERGENCE_TOOLS%\signcab.pl --dir %CUSTAPPS%\Common || goto :BLDERROR
       echo.>%CUSTAPPS%\Common\cm_signed
   )
   if not exist %CUSTAPPS%\Offlist\cm_signed (
      call %PERL% %CONVERGENCE_TOOLS%\signcab.pl --dir %CUSTAPPS%\Offlist || goto :BLDERROR
      echo.>%CUSTAPPS%\Offlist\cm_signed
   )
   call %PERL% %CONVERGENCE_TOOLS%\signcab.pl --dir %CUSTAPPS% || goto :BLDERROR
   %HOMEDRIVE%
)

REM Copy cabs from Common to root of AUTOEXEC
xcopy /Q/Y/V %CUSTAPPS%\Common %CUSTAPPS%

REM Copy custapps to langcabs/country_lang
if not exist %LANGCABS%\%COUNTRY%_%LANG% (
    mkdir %LANGCABS%\%COUNTRY%_%LANG%
    xcopy /v/y %CABS% %LANGCABS%\%COUNTRY%_%LANG% >NUL
)

if not "%CABDIR%"=="" (
  if not exist "%CABDIR%" (echo Error: %CABDIR% does not exist) & (goto :BLDERROR)
  xcopy /v/y/f %CABDIR% %CUSTAPPS%
)

REM Generate custapps.bsm.xml
REM *************************
echo.
echo Generating custapps.bsm.xml...
%PERL% %BLDSCRIPTS%\Mklinks.pl -r %CUSTAPPS%
%PERL% -I%CONVERGENCE_TOOLS%\\GenerateXML %CONVERGENCE_TOOLS%\\GenerateXML\\generatexml.pl -cabdir %CUSTAPPS%

REM Copy DIO, ini and XML files
REM ***************************
echo.
echo Copying DIO, ini, and xml files...
set DIOFILES=FLASH.DIO FLASH.DIO.alloc FLASH.DIO.cfgdata FLASH.DIO.info fsdmgr_nt.ini QCMSM.cfg.xml
if defined uBSPFLAT (
   for %%i in (%DIOFILES%) do (
      xcopy /Y/V/F "%uBSPFLAT%"\%%i %BLD_SDRIMG%
   )
) else (
   for %%i in (%DIOFILES%) do (
      if not exist %BLD_SDRIMG%\%SLANG%\%BSPLB% (
         xcopy /Y/V/F %BSPFLAT%\BSP_%BSPLB%_flatrelease\%SLANG%\%%i %BLD_SDRIMG%\%SLANG% || goto :BLDERROR
      )
   )
   echo.>%BLD_SDRIMG%\%SLANG%\%BSPLB%
)

REM List cabs
REM *********
echo.
echo Cabs merged and signed:
echo.
dir /on %CUSTAPPS%\*.cab

copy /v %CUSTAPPS%\custapps.bsm.xml %BLD_SDRIMG%

REM Generate FLASH.bin
REM ******************
echo.
echo Generating FLASH.bin...
cd %BLD_SDRIMG%
copy /V %BLD_SDRIMG%\%SLANG% >NUL
populatedio /bsmfile:custapps.bsm.xml /image:FLASH.DIO || goto :BLDERROR

REM Copy MBN/Hex files
REM ******************
cd %BLD_SDRIMG%\MBN
echo.
if defined uBSPPROD (
   if not exist "%uBSPPROD%" (set Error: %uBSPPROD% does not exist) & (goto :BLDERROR)
   echo Copying mbn and hex files...
   xcopy /V/F %uBSPPROD%\*.mbn
   xcopy /V/F %uBSPPROD%\*.hex
) else (
   if not exist "%BSPPROD%\%BSPLB%\%CONFIG%" (set Error: %BSPPROD%\%BSPLB%\%CONFIG% does not exist) & (goto :BLDERROR)
   if not exist cm_mbn_copied (
      echo Copying mbn and hex files...
      xcopy /V/F %BSPPROD%\%BSPLB%\%CONFIG%\*.mbn
      xcopy /V/F %BSPPROD%\%BSPLB%\%CONFIG%\*.hex
      echo.>cm_mbn_copied
   )
)

REM Generate *.sdr
REM **************
cd %BLD_SDRIMG%
xcopy /V/F/Y %BLDSCRIPTS%\sdr.exe ..
copy /V %BLD_SDRIMG%\MBN >NUL
cd ..
echo.
echo Generating sdr file...
sdr.exe Images %SDRFILE% || goto :BLDERROR

if not exist %CONFIG% mkdir %CONFIG%

rem Create country\operator folder and copy sdr file
call :CopySDR %COUNTRY% %OPERATOR% %SDRFILE%

goto DONE



:CopySDR & Flash.bin
rem  %1 country
rem  %2 operator
rem  %3 sdrfile

set operator=%2

if /i "%operator%"=="cus" (set operator=Customized)
if /i "%operator%"=="vod" (set operator=Vodafone)
if /i "%operator%"=="opt" (set operator=Optus)
if /i "%operator%"=="mob" (set operator=Mobilkom)
if /i "%operator%"=="win" (set operator=Wind)
if /i "%operator%"=="med" (set operator=Meditel)
if /i "%operator%"=="tmo" (set operator=T-Mobile)
if /i "%operator%"=="mov" (set operator=Movistar)
if /i "%operator%"=="tel" (set operator=Telenor)
if /i "%operator%"=="swi" (set operator=Swisscom)
if /i "%operator%"=="sun" (set operator=Sunrise)

if not exist %CONFIG%\%1\%operator%_%LANG% mkdir %CONFIG%\%1\%operator%_%LANG%
if "%SPACEID%"=="1230-2799" (
   copy /v %3 %CONFIG%
   move %3 %CONFIG%\%1\%operator%_%LANG%
) else (
   move %3 %CONFIG%\%1\%operator%_%LANG%
)
copy %BLD_SDRIMG%\FLASH.bin %CONFIG%\%1\%operator%_%LANG%\FLASH.bin || goto :BLDERROR

goto :EOF

:USAGE
echo Usage:  generateSDR /country:Australia /bsplb:R1AA042 /prodlb:R1AA057
echo                     [/config:prod] [/opr:CUS] [/lang:EN] [/nocust:1] [/sign:1] [/bsp:bsp] [/bspflat:bspflat]
echo                     [/cabdir:C:\Temp\Delivery_109510\SEMC_CustInstDir]
goto :EOF

:SWITCHERROR
echo.
echo Required switche(s) are missing and/or misspelled
goto :EXITERROR


:BLDERROR
goto :EXITERROR

:EXITERROR
pause

:DONE

popd & endlocal
