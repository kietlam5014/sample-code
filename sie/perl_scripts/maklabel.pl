###########################################################################
##
## Copyright (c) 1999, Siemens Information and Communication Networks, Inc.
## All Rights Reserved.
##
## System:       HiNet RC 3000
## Component:    bld
## SubComponent: tools
## Module:
##
## Description:  Makes, labels, and locks a given BIND label. Creates BIND
##               label on \top and \top_third_party vobs.
##
## Revision History:
##
## Date         Author  Ver Description
##
## 05/12/1999   kietl     1 Creation
##
###########################################################################
#
# Usage: maklabel BIND
#

if (@ARGV != 1) {
   print("Usage: maklabel BIND\n");
   exit 0;
}

$BIND = @ARGV[0];

chdir("\\top") || die "Cannot chdir to \\top";
system("cleartool mklbtype -ord -nc $BIND");
system("cleartool mklbtype -ord -nc \"$BIND\"-0");
system("cleartool mklbtype -ord -nc \"$BIND\"-A");

system("cleartool chevent -c \"HiNet RC 3000\" -append lbtype:$BIND");
system("cleartool chevent -c \"HiNet RC 3000\" -append lbtype:\"$BIND\"-0");
system("cleartool chevent -c \"HiNet RC 3000\" -append lbtype:\"$BIND\"-A");

system("cleartool chevent -c \"Release 1.1\" -append lbtype:$BIND");
system("cleartool chevent -c \"Release 1.1\" -append lbtype:\"$BIND\"-0");
system("cleartool chevent -c \"Release 1.1\" -append lbtype:\"$BIND\"-A");

system("cleartool lock -nusers root,kietl,sinotte lbtype:$BIND");
system("cleartool lock -nusers root,kietl,sinotte lbtype:\"$BIND\"-0");
system("cleartool lock -nusers root,kietl,sinotte lbtype:\"$BIND\"-A");
