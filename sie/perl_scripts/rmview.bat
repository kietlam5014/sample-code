@echo off
REM #####################################################################
REM ##
REM ## Copyright (c) 2000, Siemens Enterprise Networks, Inc.
REM ## All Rights Reserved.
REM ##
REM ## Description:  Batch script to remove view.
REM ## Revision History:
REM ##
REM ##  Date        Author  Ver Description
REM ##  04/20/2001  kietl     1 Creation
REM #####################################################################
REM #
color 1a
if %1.==. goto USAGE

@echo cleartool rmtag -view %1
cleartool rmtag -view %1
@echo cleartool rmview -vob \top -uuid %2
cleartool rmview -vob \xperience -uuid %2
cleartool rmview -vob \xperience_third_party -uuid %2
@echo cleartool unregister -view -uuid %2
cleartool unregister -view -uuid %2
goto DONE

:USAGE
@echo Usage:  rmview VIEWTAG UUID
@echo To get UUID, type cleartool -long VIEWTAG

:DONE
