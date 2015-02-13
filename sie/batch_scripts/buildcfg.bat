@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2000, Siemens Enterprise Networks, Inc.
REM ## All Rights Reserved.
REM ##
REM ## Description:  This file contains defined variables used by
REM ##               moabuild.bat to do the build.
REM ## Revision History:
REM ##
REM ##  Date        Author  Ver Description
REM ##
REM ##  ---------- xperience_v1.0_sjc -----------------------------------
REM ##  03/14/2003  kietl     1 Creation
REM ##  05/07/2003  kietl     2 Added comments and new definitions
REM ##  09/24/2003  kietl     3 Added build drive definitions
REM ##  10/06/2003  kietl     4 Added common definitions
REM ##  05/10/2004  kietl     1 Set environment variables based on which
REM ##                          computer is called from.
REM ##  06/10/2004  kietl     3 Add defs for build08
REM ##  06/16/2004  kietl     4 Add build view tag for build05
REM ##  06/24/2004  kietl     7 Add Colleen and Farahr
REM ##  06/24/2004  kietl     8 Define storage area for done state
REM ##  06/25/2004  kietl     10 Remove Charlotte
REM ##  06/30/2004  colleenm  11 Add defs for build02 and build09
REM ##  07/14/2004  Farahr    12 Group the common code for all the build machine. 
REM ##                           Also make all the machine usable for Merge Module.
REM ##  07/14/2004  kietl     13 Fixed typo for build06
REM ##  10/21/2004  colleenm  14 Merged added build11 and build12 machines.
REM ##  10/25/2004  colleenm  15 Fix typos for build11 and build12.  
REM ##  10/26/2004  colleenm  16 Fix typo for build11
REM ##  01/26/2005  colleenm  19 Renamed build10/11 bld drive name for consistency
REM ##  06/16/2005  kietl     20 Modified build12 snap view name
REM ##  02/18/2006  Farahr    21 Add the definition for build machine USNWKC00126SRV.
REM ##  03/22/2006  Farah     22 Add the us005 machine.
REM ##  03/29/2006  Farah     23 Fix for us005.
REM ##  05/16/2006  colleenm  33 Added machine US5DA79C
REM ##  05/18/2006  kietl     34 Modified for us5da77c (build07)
REM ##  09/28/2006  kietl     35 Temporary set DONESTOR path
REM ##  10/02/2006  kietl     36 Set DONESTOR to \\usnwkc0010fsrv\FS20050103\Dev&Test
REM ##  10/12/2006  colleenm  37 Remove outdated machines/add new ones (us5a5ec)
REM ##  10/13/2006  kietl     40 Defined packages
REM ##  11/02/2006  kietl     41 Changed view names from 6srv to 71c
REM ##  11/10/2006  colleenm  42 Modified view name, osc to xpr
REM ##  11/15/2006  colleenm  43 Added us5da5cc for iwr builds
REM ##  11/15/2006  colleenm  44 typo for machine name
REM #####################################################################
REM #

:BLDCFG
REM
REM Common variables
REM ----------------
set CMTOOLS=\xperience_tools\cm\batch
set DONESTOR="\\usnwkc0010fsrv\FS20050103\Dev&Test\BuildandInstallStuff
set PACKAGES=\\usnwkc0010fsrv\FS20050103\Development\Packages
set CT=cleartool
set NUSER="topadm"


set IWR_LABELDRV=L
set XPR_LABELDRV=L
set MCU_LABELDRV=K

set XPRBLDDRV=S
set MCUBLDDRV=X
set IWRBLDDRV=q

set MINSTALLDRV=Y
set IINSTALLDRV=Z
set XINSTALLDRV=Z

call :%COMPUTERNAME% & goto :EOF
goto :EOF


REM USNWKC00125SRV, us5da5cc, us5da5dc, us5da5ec, us5da5fc, us5da71c, us5da77c and us5da79c are XP machine.

:USNWKC00125SRV
set XBLDVIEWTAG=topadm_5srv_osc_bld
set MBLDVIEWTAG=topadm_5srv_mcu_bld
set SXVIEW=C:\view\topadm_5srv_xinstall_snap
set SMVIEW=C:\view\topadm_5srv_minstall_snap
goto :EOF

:us5da5cc
set XBLDVIEWTAG=topadm_us5da5cc_xpr_bld
set MBLDVIEWTAG=topadm_us5da5cc_mcu_bld
set BLDVIEWTAG=topadm_us5da5cc_iwr_bld
set SIVIEW=C:\view\topadm_us5da5cc_iinstall_snap
goto :EOF

:us5da5dc
set XBLDVIEWTAG=topadm_us5da5dc_xpr_bld
set MBLDVIEWTAG=topadm_us5da5dc_mcu_bld
set SXVIEW=C:\view\topadm_us5da5dc_xinstall_snap
set SMVIEW=C:\view\topadm_us5da5dc_minstall_snap
goto :EOF

:us5da5ec
set BLDVIEWTAG=topadm_us5da5ec_iwr_bld
set XBLDVIEWTAG=topadm_us5da5ec_xpr_bld
set MBLDVIEWTAG=topadm_us5da5ec_mcu_bld
set SXVIEW=C:\view\topadm_us5da5ec_xinstall_snap
set SMVIEW=C:\view\topadm_us5da5ec_minstall_snap
set SIVIEW=C:\view\topadm_us5da5ec_iinstall_snap
goto :EOF

:us5da5fc
set BLDVIEWTAG=topadm_us5da5fc_iwr_bld
set XBLDVIEWTAG=topadm_us5da5fc_xpr_bld
set MBLDVIEWTAG=topadm_us5da5fc_mcu_bld
set SXVIEW=C:\view\topadm_us5da5fc_xinstall_snap
set SMVIEW=C:\view\topadm_us5da5fc_minstall_snap
set SIVIEW=C:\view\topadm_us5da5fc_iinstall_snap
goto :EOF

:us5da71c
set XBLDVIEWTAG=topadm_us5da71c_xpr_bld
set MBLDVIEWTAG=topadm_us5da71c_mcu_bld
set SXVIEW=C:\view\topadm_us5da71c_xinstall_snap
set SMVIEW=C:\view\topadm_us5da71c_minstall_snap
goto :EOF

:us5da77c
set BLDVIEWTAG=topadm_us5da77c_iwr_bld
set SIVIEW=C:\view\topadm_us5da77c_install_snap
goto :EOF

:us5da79c
set BLDVIEWTAG=topadm_us5da79c_bld
set SIVIEW=C:\view\topadm_us5da79c_install_snap 
goto :EOF


REM USNWKC00122SRV is a window 2000 machine

:USNWKC00122SRV
set BLDVIEWTAG=topadm_2srv_bld
set SIVIEW=D:\views\topadm_2srv_iinstall_snap
goto :EOF


