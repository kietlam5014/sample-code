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
## Description:  Removes all files in obj and bin directory
##
## Revision History:
##
## Date         Author  Ver Description
##
## 11/09/2002   kietl     1 Creation
###########################################################################
#
# Usage: rmlog


if (@ARGV != 0) {
   print("Usage: rmlog\n");
   exit 0;
}

$file1 = 'c:\temp\tmpfile1';      # Contains all path\filename.log

print("Removing files in 'obj' dirs...\n");
system("dir /b/s /ad obj > $file1");

open(TXTFILE1, $file1);
while (<TXTFILE1>) {
   chop($_);
   system("del /s /q $_");
}
close(TXTFILE1);

print ("Removing files in 'bin' dirs...\n");
system("dir /b/s /ad bin > $file1");
open(TXTFILE1, $file1);
while (<TXTFILE1>) {
   chop($_);
   system("del /s /q $_");
}
close(TXTFILE1);

print ("Removing .NET *.user, *.log and *.keep files in all dirs...\n");
system("dir /s/b *.user *.log *.keep > $file1");
open(TXTFILE1, $file1);
while (<TXTFILE1>) {
   chop($_);
   system("del /s /q $_");
}
close(TXTFILE1);



