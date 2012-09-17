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
# Description:  Assign DMS to a user.
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
# 10/02/09  10101482  Initial creation
#================================================================================#
use strict;
use Getopt::Long;
use CQPerlExt;

# Defined Variables
#
my $USERID     = $ENV{'USERNAME'};
my $PASSWD     = $ENV{'CQPASSWD'};
my $DBNAME     = $ENV{'CQDBNAME'};
my $DBSET      = $ENV{'CQDBSET'};
my ($DMSID, $help);

# Default user to be assigned
my $CQUSERID   = "10101619";
my $CQUSERNAME = "Gonzales, Michael";

sub nextAction($);
sub CQ_error($);
sub usage();

GetOptions ('dms=s' => \$DMSID, 'help|?' => \$help);

if ( ! $DMSID or defined $help ) {
   usage();
}

# Get current Session and Logon
my $CQsession = CQSession::Build();
$CQsession->UserLogon($USERID, $PASSWD, $DBNAME, $DBSET);

# Get a record
my $entity;
eval ("\$entity = \$CQsession->GetEntity(\"issue\", \$DMSID);");
&CQ_error("EditEntity") if ($@);

if (nextAction("assign")) {
   # do assign here
   eval ("\$CQsession->EditEntity(\$entity, \"Assign\");");
   &CQ_error("EditEntity") if ($@);
   
   $entity->SetFieldValue("assigned_to", $CQUSERID);
   $entity->SetFieldValue("assigned_to_name", $CQUSERNAME);

   eval ("\$entity->Validate();");
   &CQ_error("Validate") if ($@);
   eval ("\$entity->Commit();");
   &CQ_error("Commit") if ($@);
   
   print "$DMSID assigned successful\n\n";
}

sub nextAction($) {
   my ($name) = @_;

   # Search for a legal action with which to modify the record   
   my $actionDefList = $entity->GetLegalActionDefNames();
   foreach my $actionName (@$actionDefList) {
       if ($actionName =~ m/$name/i) {
           return 1;
       }
    }
    return 0;
}

# Close Session
CQSession::Unbuild($CQsession);


#----------------------------------------------------------------------#
# Subroutine    : CQ_error
# Purpose       : Displays the error given by a failed ClearQuest API
#                 command.
# Parameters    : $method - name of the CQ API method that failed
# Returns       : none
#----------------------------------------------------------------------#
sub CQ_error($) {
  my ($method) = @_;
  print ("ERROR: $method failed with the following message:\n$@\n");
  exit(1);
}


#----------------------------------------------------------------------#
# Subroutine    : usage
# Purpose       : prints usage of this script
# Parameters    :
# Returns       :
#----------------------------------------------------------------------#
sub usage() {
    print "Unknown options: @_\n" if (@_);
    print "usage: CQassign --dms [--help|-?]\n";
    print "   ex: CQassign --dms DMS00529230\n\n";
    exit(1);
}

__END__
:endperl
