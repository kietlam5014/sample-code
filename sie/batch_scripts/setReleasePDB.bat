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
## Description: Modify *.csproj to set DebugSymbols to true for Release mode
##
## Revision History:
##
## Date         Author  Ver Description
##
## 10/16/03     kietl     1 Creation
###########################################################################

require 'CMD.pm';

# ############################################################################################### #
# Global Definition
# ############################################################################################### #
@gDSP = ();


$CMD::MIN   = 0;
$CMD::USAGE = "[--path]";
@CMD::OPTS  =
(
  "path=s",
);
%CMD::ARGS  = ();

%CMD::HELP  =
(
  "path"     => "path (e.g. \\top\\acdsrv)",
);

# ############################################################################################### #
# Parse Command-line and set variables
# ############################################################################################### #
CMD::parse();
local $PATH  = $CMD::OPT{"path"} if(exists $CMD::OPT{"path"});

# ############################################################################################### #
# Main Program
# ############################################################################################### #
&getprjs($PATH);
print ".csproj to update:\n";
&listdsp;
&updatedsp;


# ############################################################################################### #
# Get list of *.csproj and store in an array
# ############################################################################################### #
sub getprjs {
   my ($lpath) = @_;
   unless (open(TF, sprintf("dir /b/s /a-d $lpath\\*.csproj |"))) {
      return "";
   }
   while (<TF>) {
      push(@gDSP, $_);
   }
   close(TF);
}

# ############################################################################################### #
# Update DSP
# ############################################################################################### #
sub updatedsp {
   foreach $n (@gDSP) {
      if (&isCheckout($n)) {
         &setDebugSymbols($n);
      }
      else {
         print "checking out...\n";
         system("cleartool co -nc -unres -ver $n");
         &setDebugSymbols($n);
      }
   }
}   

# ############################################################################################### #
# List DSP
# ############################################################################################### #
sub listdsp {
   foreach $n (@gDSP) {
      print "    $n";
   }
}

# ############################################################################################### #
# Scan content of csproj and set setDebugSymbols to true for Release config
# ############################################################################################### #
sub setDebugSymbols {
   my ($filedsp) = @_;
   chop($filedsp);
   local $tempfile = $filedsp . ".tmp";
   local $ncmd;
   open(OUTFILE, ">$tempfile");
   open(INFILE, $filedsp);
   while (<INFILE>) {
      $_ =~ s/DebugSymbols = "false"/DebugSymbols = "true"/;
      print OUTFILE $_;
   }
   close(INFILE);
   close(OUTFILE);
   system("xcopy $tempfile $filedsp /q/v/y");
   unlink($tempfile);
   
   # Uncheckedout if no content changed (e.g deliver not found)
   $ncmd = "cleartool diff -pred $filedsp";
   $ncmd = `$ncmd`;
   chop($ncmd);
   if ($ncmd eq "Files are identical") {
      print "No changed for $filedsp\n";
      system("cleartool unco -rm $filedsp");
   }
   
}

# ############################################################################################### #
# True if it is checkedout
# ############################################################################################### #
sub isCheckout {
   my ($n) = @_;
   return (-w $n) ? 1 : 0;
}

__END__
:endOfPerl
