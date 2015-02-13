@rem = ' PERL for Windows NT -- ccperl must be in search path
@echo off
setlocal
set BSCRIPT=%0
shift
IF "%0" EQU "GO" goto startperl

set path=\xperience_third_party\PERL\bin;%path%
clearaudit /c %BSCRIPT% GO %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
endlocal
goto endofperl

:startperl
shift
set SCRIPT=%BSCRIPT%
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
set PERL5LIB=\xperience_third_party\PERL\LIB;\xperience\bld\tools\pm
PERL %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1
endlocal
goto endofperl
@rem ';
###########################################################################
##
## Copyright (c) 2001-2003, Siemens Enterprise Networks
## All Rights Reserved.
##
## Description: Verify if source is valid
##
## Revision History:
##
## Date     Author  Ver Description
##
## 04/07/03 yates     1 Creation
## 05/15/03 kietl     3 Modified for use with ClearCase trigger
## 05/16/03 kietl     6 Modified to verify only the differences
## 05/22/03 kietl     8 Added error message
## 05/28/03 kietl    11 Added drive letter. Require for checkin in Explorer
###########################################################################
use strict;

my($pathfile) = @ARGV[0];
my($os, $lang, $source, $dest);
my(@field, $curdrv, $status);

my($reject) = 1;

$curdrv = $pathfile;
$curdrv =~ s/(.*:).*/\1/;


#
## Verify only the differences
#
unless (open(FILE, sprintf("cleartool diff -ser -pred -option -quiet %s |", $pathfile))) {
   print ("Error comparing input file $pathfile with its predecessor");
}

while (<FILE>) {
	if ($_ =~ /^>[^>]/) {
	$_ =~ s/^> //;  # Removes starting '> ' from diff output
	}
	next if (/\s*\#/);
	next if (/^-|^</); # Skips if begins with - or <
	$_ = $_ . "\n" if (! /\n/);
	@field = split(/\|/, $_);
	if (@field < 5) {
		($lang, $source, $dest) = split(/\|/, $_);
	} else {
		($os, $lang, $source, $dest) = split(/\|/, $_);
	}
	if (defined($dest)) {
		next if (/\s*\#/);
		$source =~ s/(^\s+)|(\s+$)//g;
		$source = $curdrv."\\".$source;
		$status = system("cleartool ls -short -nxname $source > NUL");
		if ($status != 0) {
			printf "Invalid pathname in source path.\n";
			exit $reject;
		}
	}
}

__END__
:endOfPerl
