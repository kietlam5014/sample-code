@rem = ' PERL for Windows NT -- ccperl must be in search path
@echo off
setlocal
set SCRIPT=%0
shift
set path=\top_third_party\jdk\1.1.6\bin;\top_third_party\PERL\bin;%path%
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
set PERL5LIB=\top_third_party\PERL\LIB;\top\bld\tools\pm
PERL %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1
endlocal
goto endofperl
@rem ';
###########################################################################
##
## Copyright (c) 2001, Siemens Enterprise Networks
## All Rights Reserved.
##
## Description: Replace all top\..\deliver with top_do\..\deliver in .dsps
##
## Revision History:
##
## Date         Author  Ver Description
##
## 06/29/2001   kietl     1 Creation
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
&getdsps($PATH);
print "Dsps to update:\n";
&listdsp;
&updatedsp;


# ############################################################################################### #
# Get list of *.dsp and store in an array
# ############################################################################################### #
sub getdsps {
   my ($lpath) = @_;
   unless (open(TF, sprintf("dir /b/s /a-d $lpath\\*.dsp |"))) {
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
         &replaceWithTopdo($n);
      }
      else {
         system("cleartool co -nc -unres -ver $n");
         &replaceWithTopdo($n);
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
# Scan content of dsp and replace all \top\..\deliver with \top_do\..\deliver
# ############################################################################################### #
sub replaceWithTopdo {
   my ($filedsp) = @_;
   chop($filedsp);
   local $tempfile = $filedsp . ".tmp";
   local $ncmd;
   open(OUTFILE, ">$tempfile");
   open(INFILE, $filedsp);
   while (<INFILE>) {
      $_ =~ s/\\top\\([a-zA-Z\\]*)deliver/\\top_do\\\1deliver/g;
      print OUTFILE $_;
   }
   close(INFILE);
   close(OUTFILE);
   system("xcopy $tempfile $filedsp /q /v");
   unlink($tempfile);
   
   # Uncheckedout if no content changed (e.g \top\..\deliver not found)
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
   local $r = "cleartool lsco -short $n";
   local $result = `$r`;
   $result;
}

__END__
:endOfPerl
