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
## Copyright (c) 2001, Siemens Enterprise Networks LLC
## All Rights Reserved.
##
## Description: Searches all logs and them to web directory
##
## Revision History:
##
## Date     Author  Ver Description
##
## 10/25/02 kietl     1 Creation
##-------------------------------------------------------------------------
## 02/25/04 kietl     1 Added Media Server check
## 03/22/04 paynec    2 Add message if component not found from build number
###########################################################################
require 'CMD.pm';

@gLOG = ();

$CMD::MIN   = 0;
$CMD::USAGE = "[--build]";
@CMD::OPTS  =
(
  "build=s",
);

%CMD::ARGS  = ();

%CMD::HELP  =
(
  "build"    => "build #"
);

# ############################################################################################### #
# Parse Command-line and set variables
# ############################################################################################### #
CMD::parse();

local $build = $CMD::OPT{"build"} if(exists $CMD::OPT{"build"});
local $wdir = "\\\\ntap02\\swtoldev\\swprod\\buildlog";


# ############################################################################################### #
# Main Program
# ############################################################################################### #
printf "\n%s.\n", CMD::strerror("Posting log files..");
mkdir("$wdir\\$build",0777) || die "cannot mkdir $wdir\\$build";

if ($build =~ /XPR/i) {
   chdir("\\xperience") || die "cannot cd into \\xperience";
} elsif ($build =~ /MCU/i) {
   chdir("\\mcu") || die "cannot cd into \\mcu";
} elsif ($build =~ /IWR/i) {
   chdir("\\iwr") || die "cannot cd into \\iwr";
} else {
   print "Error: Component could not be determined from $build \n";
}

&getlog;

foreach $n (@gLOG) {
   chop($n);
   $n =~ s/.*:(.*)/\1/;     # removes drive letter
   system("copy $n $wdir\\$build");
}
system("echo.>\\\\ntap02\\swtoldev\\swprod\\.builds\\build_$build");


# ############################################################################################### #
# Get list of log files and store in an array
# ############################################################################################### #
sub getlog {
   unless (open(TF, sprintf("dir /b/s *.log |"))) {
      return "";
   }
   while (<TF>) {
      push(@gLOG, $_);
   }
   close(TF);
}

__END__
:endOfPerl
