###########################################################################
##
## Copyright (c) 1999, Siemens Information and Communication Networks, Inc.
## All Rights Reserved.
##
## Description:  Recursively label files in \xperience_deliver\Debug
##
## Revision History:
##
## Date       Author  Ver Description
##
## 02/06/03   kietl     1 Creation
##                      3 Added parameters
## 04/21/03   kietl     5 Modified to label new component
## 05/15/03   kietl     7 Modified for use with loadbuild makefile
## 07/14/03   kietl     8 Changed to recgonize new version schema.
################### OpenScape  ######################
## 12/08/03   paynec    1 Add Version 2 label
## 10/12/04   kietl     5 Do not die on unknown label
###########################################################################
#
# Usage: setLGB BIND {DEBUG|RELEASE}

if (@ARGV < 2) {
   print("Usage: setLGB BIND {DEBUG | RELEASE}\n");
   exit 1;
}

$BIND = @ARGV[0];
$RTYPE = @ARGV[1];
$TMPFILE = $ENV{"TEMP"} . "\\tmpfile";


$RTYPE =~ tr/A-Z/a-z/;

if ($RTYPE eq "debug") {
   if ($BIND =~ /1.02/) {
      $LABEL = "XPR_DROP2_LAST_GOOD_DEBUG";
   } elsif ($BIND =~ /1.03/) {
        $LABEL = "XPR_DROP3_LAST_GOOD_DEBUG";
   } elsif ($BIND =~ /1.40/) {
        $LABEL = "XPR_DROP4_LAST_GOOD_DEBUG";
   } elsif ($BIND =~ /1.50/) {
        $LABEL = "XPR_LAST_GOOD_BUILD_DEBUG";
   } elsif ($BIND =~ /2.40/) {
        $LABEL = "OSC_LAST_GOOD_BUILD_DEBUG";
   } elsif ($BIND =~ /2.41/) {
        $LABEL = "OSC_LAST_GOOD_BUILD_DEBUG";
   } elsif ($BIND =~ /2.50/) {
        $LABEL = "OSC_LAST_GOOD_BUILD_DEBUG";
   } elsif ($BIND =~ /2.80/) {
        $LABEL = "OSC_LAST_GOOD_BUILD_DEBUG";
   } else {
      die "Unknown label\n";
   }
} elsif ($RTYPE eq "release") {
   if ($BIND =~ /1.02/) {
      $LABEL = "XPR_DROP2_LAST_GOOD";
   } elsif ($BIND =~ /1.03/) {
        $LABEL = "XPR_DROP3_LAST_GOOD";
   } elsif ($BIND =~ /1.40/) {
        $LABEL = "XPR_DROP4_LAST_GOOD";
   } elsif ($BIND =~ /1.50/) {
        $LABEL = "XPR_LAST_GOOD_BUILD";
   } elsif ($BIND =~ /2.40/) {
        $LABEL = "OSC_LAST_GOOD_BUILD";
   } elsif ($BIND =~ /2.41/) {
        $LABEL = "OSC_LAST_GOOD_BUILD";
   } elsif ($BIND =~ /2.50/) {
        $LABEL = "OSC_LAST_GOOD_BUILD";
   } elsif ($BIND =~ /2.80/) {
        $LABEL = "OSC_LAST_GOOD_BUILD";
   } else {
        print "Unknown label\n";
	exit 0;
   }
}

print ("Labeling $LABEL...\n");


if ($RTYPE eq "debug") {
   chdir("\\xperience_deliver\\Debug") || die "Cannot chdir to \\xperience_deliver";
   system("cleartool mklabel -rec -rep $LABEL .");
   system("dir /b/s /ad > $TMPFILE");
   system("cleartool rmlabel $LABEL .");
}
elsif ($RTYPE eq "release") {
   chdir("\\xperience_deliver\\Release") || die "Cannot chdir to \\xperience_deliver";
   system("cleartool mklabel -rec -rep $LABEL .");
   system("dir /b/s /ad > $TMPFILE");
   system("cleartool rmlabel $LABEL .");
}

open(TXTFILE, $TMPFILE);
while (<TXTFILE>) {
   chop($_);
   system("cleartool rmlabel $LABEL $_");
}
close(TXTFILE);
unlink($TMPFILE);
