@echo off
@rem ----------------------------------------------------
@rem  Date      Author   Description
@rem
@rem  09/21/04  kietl    Removes all ReadOnly attributes
@rem                     Use in Snapshot view packaging
@rem  10/05/04  kietl    check for existing VOBS
@rem  12/07/05  kietl    Added mcu_third_party
@rem ----------------------------------------------------

if exist \iwr (cd \iwr && attrib -R /S)
if exist \iwr_deliver (cd \iwr_deliver && attrib -R /S)
if exist \iwr_third_party (cd \iwr_third_party && attrib -R /S)
if exist \rulesservice (cd \rulesservice && attrib -R /S)
if exist \xperience (cd \xperience && attrib -R /S)
if exist \xperience_tools (cd \xperience_tools && attrib -R /S)
if exist \xperience_deliver (cd \xperience_deliver && attrib -R /S)
if exist \xperience_third_party (cd \xperience_third_party && attrib -R /S)
if exist \xpr_install_deliver (cd \xpr_install_deliver && attrib -R /S)
if exist \xpr_installation (cd \xpr_installation && attrib -R /S)
if exist \mcu_third_party (cd \mcu_third_party && attrib -R /S)
cd \xpr_installation\bld
attrib +R *.state
attrib +R *.log
