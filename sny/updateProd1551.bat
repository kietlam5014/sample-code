@rem = ' Perl for Windows NT
@echo off
setlocal & pushd
set SCRIPT=%0
shift
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
IF NOT EXIST %HOMEDRIVE%\.cm\buildcfg.bat (echo Error: %HOMEDRIVE%\.cm\buildcfg not found) & goto :endperl
call %HOMEDRIVE%\.cm\buildcfg.bat
cqperl %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1
endlocal & popd
goto :endperl
@rem ';
#================================================================================#
# Copyright (c) 2010, Sony Ericsson
# All Rights Reserved.
#
# Author: Kiet Lam (10101482)
#
# Description:  Get freeze label from Notes section of the DMS and update prod 1551
#
# Requirement:  %HOMEDRIVE%\.cm\buildcfg.bat
#    defined the following in buildcfg.bat
#       set CQPASSWD=your-login-password
#       set CQDBNAME=DMS
#       set CQDBSET=CQMS.SE.USSV
#
#
# Revision History:
#
# Date      Author    Description
#--------------------------------------------------------------------------------
# 10/01/25  10101482  Initial creation
#================================================================================#
use strict;
use Getopt::Long;
use CQPerlExt;

# Get current view
my $VIEW = "Z:\\" . `cleartool pwv -short`;
chop($VIEW);

# Defined Variables
#
my $USERID    = $ENV{'USERNAME'};
my $PASSWD    = $ENV{'CQPASSWD'};
my $DBNAME    = $ENV{'CQDBNAME'};
my $DBSET     = $ENV{'CQDBSET'};
my ($DMSFILE, $help);
my $PROD1551  = "$VIEW\\USSV_Products_001\\crh1062001_vulcan_product\\1551_crh1062001.cfg";

# Get current Session
my $CQsession = CQSession::Build();

# Logon
$CQsession->UserLogon($USERID, $PASSWD, $DBNAME, $DBSET);

GetOptions ('dmsfile=s' => \$DMSFILE, 'help|?' => \$help);
if ( ! $DMSFILE or defined $help ) {
   usage();
}

# Checked out 1551 cfg
system("cleartool desc -short $PROD1551 | findstr CHECKEDOUT");
if ($?) { # checked out if it's not
   system("cleartool co -unres -nc $PROD1551");
}

# Read textfile containing list of DMS
open(INFILE, $DMSFILE) or die "Can't open $DMSFILE";
LINE: while(<INFILE>) {
   next LINE if /^#/;  # skip comments
   next LINE if /^$/;  # skip blank line
   # Get a record
   # test DMS DMS00529230
   chomp($_);
   my $entity = $CQsession->GetEntity("issue", $_);
   my $fieldname = "Notes_Log";
   my $fieldOBJ   = $entity->GetFieldValue($fieldname);
   my $fieldvalue = $fieldOBJ->GetValue();

   # Get freeze label from fieldvalue
   if ($fieldvalue =~ m/cclb: (.*)/) {
      my $lb = $1;
      updateCFG($lb);
   }
} # end while DMSFILE
close(INFILE);


sub updateCFG {
   my ($lb) = @_;
   my $match = 0;
   
   my ($modid, $rnum) = split("_", $lb);
   open(OUTFILE2, ">prod.cfg") or die "Can't open prod.cfg";
   open(INFILE2, "1551_crh1062001.cfg") or die "Can't open $PROD1551";
   LINE2:
   while(<INFILE2>) {
      if ($match) {
         print OUTFILE2 $_;
         next LINE2;
      }
      elsif (/^USSV|^LDS/) {
         my ($vobpath, $cnhrnum) = split (" ", $_);
         my ($m, $r) = split("_", $cnhrnum);
         if ($m eq $modid) {
            print OUTFILE2 "$vobpath\t$lb\n";
            $match = 1;
            next LINE2;
         }
      }
      print OUTFILE2 $_;
   }
   if (! $match) {
      print "\n\n**** $modid NOT FOUND in 1551_crh1062001.cfg ****\n";
   }
   close(INFILE2);
   close(OUTFILE2);
}


#----------------------------------------------------------------------#
# Subroutine    : usage
# Purpose       : prints usage of this script
# Parameters    :
# Returns       :
#----------------------------------------------------------------------#
sub usage() {
    print "Unknown options: @_\n" if (@_);
    print "usage: updateProd1551 --dmsfile dmsfile\n";
    print "   ex: updateProd1551 --dmsfile dmsfile.txt\n";
    exit;
}


# Close Session
CQSession::Unbuild($CQsession);


__END__
:endperl
