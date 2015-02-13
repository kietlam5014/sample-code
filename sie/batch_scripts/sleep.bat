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
## Copyright (c) 2003, Siemens Enterprise Networks LLC
## All Rights Reserved.
##
## Description: Sleep for number of seconds given.
##
## Revision History:
##
## Date     Author  Ver Description
##
## 10/31/03 kietl     1 Creation
###########################################################################
require 'CMD.pm';

# ######################################################################## #
# Global Definition
# ######################################################################## #

$CMD::MIN   = 0;
$CMD::USAGE = "[--secs]";
@CMD::OPTS  =
(
  "secs=s",
);
%CMD::ARGS  = ();

%CMD::HELP  =
(
  "secs"     => "Number of seconds to sleep",
);

# ############################################################################################### #
# Parse Command-line and set variables
# ############################################################################################### #
CMD::parse();
local $Secs  = $CMD::OPT{"secs"} if(exists $CMD::OPT{"secs"});

sleep $Secs

__END__
:endOfPerl
