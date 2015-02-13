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
## Description:  Recursively label files in \xperience_deliver\Debug
##
## Revision History:
##
## Date       Author  Ver Description
##
## 02/06/03   kietl     1 Creation
###########################################################################
#
# Usage: setDGoodBld

$TMPFILE = 'c:\temp\tmpfile';

print ("Labeling LAST_GOOD_BUILD_DEBUG...\n");


chdir("\\xperience_deliver\\Debug") || die "Cannot chdir to \\xperience_deliver";
system("dir /b/s /a-d > $TMPFILE);

open(TXTFILE, $TMPFILE);
while (<TXTFILE>) {
   chop($_);
   system("cleartool mklabel -rep LAST_GOOD_BUILD_DEBUG $_");
}
close(TXTFILE);
unlink($TMPFILE);
