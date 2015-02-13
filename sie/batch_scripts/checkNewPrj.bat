@rem = ' PERL for Windows NT -- ccperl must be in search path
@echo off
setlocal
set SCRIPT=%0
shift
set path=\xperience_third_party\PERL\bin;%path%
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
set PERL5LIB=\xperience_third_party\PERL\LIB;\xperience\bld\tools\pm
PERL %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1
endlocal
goto endofperl
@rem ';
###########################################################################
##
## Copyright (c) 2001, Siemens Enterprise Networks
## All Rights Reserved.
##
## Description: Check for any new Projects not in xperience.sln
##
## Revision History:
##
## Date     Author  Ver Description
##
## 03/13/03 kietl     1 Creation
## 03/26/03 kietl     2 Skip check of ~
###########################################################################
require 'CMD.pm';

# ############################################################################################### #
# Global Definition
# ############################################################################################### #

$CMD::MIN   = 0;
$CMD::USAGE = "[--file]";
@CMD::OPTS  =
(
  "file=s",
);
%CMD::ARGS  = ();

%CMD::HELP  =
(
  "file"     => "List of all current projects",
);

$XPRSLN = "\\xperience\\bld\\xperience.sln";

# ############################################################################################### #
# Parse Command-line and set variables
# ############################################################################################### #
CMD::parse();
local $File  = $CMD::OPT{"file"} if(exists $CMD::OPT{"file"});

# ############################################################################################### #
# Open File containing list of projects and store into a hash
# ############################################################################################### #
CMD::abort($!, sprintf("Error opening File: '%s'", $File)) if(! open(INFILE, $File));
while(<INFILE>) {
   chop($_);
   my ($path,$proj) = m#(.*)\\(.*)#;
   $path =~ s/.*:(.*)/\1/;
   if ($proj =~ /~/) {
   } else {
      &isProjExist($path,$proj);
   }
}
close(INFILE);


sub isProjExist {
   my ($pth,$prj) = @_;
   local $match = 0;
   CMD::abort($!, sprintf("Error opening File: '%s'", $XPRSLN)) if(! open(XPRFILE,$XPRSLN));
   while(<XPRFILE>) {
      chop($_);
      if ($_ =~ /$prj/) {
         $match = 1;
      }
   }
   if ($match eq 0) { print "New project: $pth\\$prj\n" };
   close(XPRFILE);
}

__END__
:endOfPerl
