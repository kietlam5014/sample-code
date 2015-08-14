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
## Description: Parse Config Specs and replace <*BIND> with *_$BIND
##              Final result is in %TMP%. Used by MOABuild
##
## Revision History:
##
## Date     Author  Ver Description
##
## 04/07/03 kietl     1 Creation
## 02/24/04 kietl     1 Added Media Server
###########################################################################
require 'CMD.pm';

# ############################################################################################### #
# Global Definition
# ############################################################################################### #

$CMD::MIN   = 0;
$CMD::USAGE = "[--file]\t[--bind]";
@CMD::OPTS  =
(
  "file=s",
  "bind=s",
);
%CMD::ARGS  = ();

%CMD::HELP  =
(
  "file"     => "Config Specs file.",
  "bind"     => "BIND (ex. 1.04.0030.00)",
);

# ############################################################################################### #
# Parse Command-line and set variables
# ############################################################################################### #
CMD::parse();
local $File  = $CMD::OPT{"file"} if(exists $CMD::OPT{"file"});
local $Bind = $CMD::OPT{"bind"} if(exists $CMD::OPT{"bind"});
local $TMP = $ENV{"TMP"};
local $TMPFILE = "$TMP\\$File";

# ############################################################################################### #
# Open file containing the config rules and replace <X|I|MBIND> with XPR|IWR|MCU_$BIND
# ############################################################################################### #
open(OUTFILE, ">$TMPFILE");
CMD::abort($!, sprintf("Error opening File: '%s'", $File)) if(! open(INFILE, $File));
while(<INFILE>) {
   if (/\<XBIND/) {
      chop($_);
      $_ =~ s/\<.*//;  # Discard everything after first <
      print OUTFILE $_ . "XPR_" . $Bind . "\n";
      next;
   }
   elsif (/\<MBIND/) {
      chop($_);
      $_ =~ s/\<.*//;  # Discard everything after first <
      print OUTFILE $_ . "MCU_" . $Bind . "\n";
      next;
   }
   elsif (/\<IBIND/) {
      chop($_);
      $_ =~ s/\<.*//;  # Discard everything after first <
      print OUTFILE $_ . "IWR_" . $Bind . "\n";
      next;
   }
   print OUTFILE $_;
}
close(INFILE);
close(OUTFILE);

__END__
:endOfPerl
