@rem = ' PERL for Windows NT -- ccperl must be in search path
@echo off
setlocal
set SCRIPT=%0
shift
set path=\xperience_third_party\PERL\bin;%path%
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
set PERL5LIB=\xperience_third_party\PERL\LIB;\xperience_tools\cm\batch\pm
PERL %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1
endlocal
goto endofperl
@rem ';
###########################################################################
##
## Copyright (c) 2006, Siemens Communications
## All Rights Reserved.
##
## Description: Add <add name="XmlSerialization.Compilation" value="4"/> under
##              <system.diagnostics>
##                      <switches>
##
## Revision History:
##
## Date         Author  Ver Description
##
## 04/10/2006   kietl     1 Creation
###########################################################################

require 'CMD.pm';

$TMP = $ENV{"TMP"};
$FrameworkDir = $ENV{"FrameworkDir"};
$FrameworkVersion = $ENV{"FrameworkVersion"};
$MCONFIG = "$FrameworkDir\\$FrameworkVersion\\CONFIG\\machine.config";

$Serial = q(<add name="XmlSerialization.Compilation" value="4"/>);
$T = q(<!-- <add name="SwitchName" value="4"/>  -->);
$in1 = 0;
$in2 = 0;
$in3 = 0;

open(OUTFILE,">$TMP\\machine.config");

open(INFILE, $MCONFIG);
while (<INFILE>) {
   if ($in3) {
      if ($_ !~ m/XmlSerialization/g) {
         print OUTFILE "\t\t\t$Serial\n";
      }
      $in3 = 0;
   }
   if ($in2) {
      if (/$T/) {
         $in2 = 0;
         $in3 = 1;
      }
   }

   if ($in1) {
      if (/\<switches\>/) {
         $in1 = 0;
         $in2 = 1;
      }
   }
   if (/\<system.diagnostics\>/) {$in1 = 1;}
   print OUTFILE $_;
}

close(INFILE);
close(OUTFILE);


__END__
:endOfPerl
