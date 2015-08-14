@rem = ' Perl for Windows NT
@echo off
setlocal & pushd
set SCRIPT=%0
shift
IF NOT EXIST %SCRIPT% set SCRIPT=%SCRIPT%.bat
perl %SCRIPT% %0 %1 %2 %3 %4 %5 %6 %7 %8 %9 2>&1 | wtee.exe build_%COMPUTERNAME%_%date:~4,2%-%date:~7,2%_%time:~0,2%.%time:~3,2%.log
endlocal & popd
goto :endperl
@rem ';
#================================================================================#
# Author: Kiet Lam (10101482)
# Date: 2009
## Description:  build all languages by calling stagecabs and
#                generateSDR scripts.
#
# Revision History:
#
# Date      Author    Description
#--------------------------------------------------------------------------------
# 09/05/20  10101482  Initial creation
# 09/08/20  10101482  Copy build result to ConvergenceSW shared folder
# 09/08/28  10101482  Copy mbn/hex files and able to build with no cust (cdr)
# 09/09/02  10101482  Updated to build both dev and dev_eval
# 09/09/03  10101482  Wrapped batch script around perl and build output will be logged
# 09/09/11  10101482  No need to pass VIEW to generateSDR script
# 09/09/18  10101482  Copy langs and build.log to Vulcan share
# 09/10/02  10101482  Copy LANGCABS to vulcan share
# 09/10/06  10101482  Sign by default
#================================================================================#
use strict;
use warnings;
use Getopt::Long;


## Set Environment
#
my $PATH = $ENV{'PATH'};
my $HOMEDRIVE = $ENV{'HOMEDRIVE'};
my $COMPUTERNAME = $ENV{'COMPUTERNAME'};
my $OS = $ENV{'OS'};
my $USERNAME = $ENV{'USERNAME'};
my $BUILTSW = "$HOMEDRIVE\\Temp\\builtsw";

## Defined variables
#
my $CONVERGENCE_UNFPROD = "\\\\corpusers.net\\ussv\\ConvergenceSW\\Vulcan\\Product\\Unofficial\\Testing";
my $BLDSCRIPTS = "";
my $TMPDELCAB     = "$BUILTSW\\CABS";
my $TMPDELLANG    = "$BUILTSW\\LANGCABS";
my $TMPDELPROD    = "$BUILTSW\\sdr\\Prod";
my $TMPDELDEV     = "$BUILTSW\\sdr\\Dev";
my $TMPDELDEVEVAL = "$BUILTSW\\sdr\\Dev_Eval";
my $TMPDELIMG     = "$BUILTSW\\sdr\\Images";
my $DATETIME      = localtime(time);
my $MKTFILE       = "market.txt";
my %Market;
my ($VIEW, $BSPLB, $PRODLB, $LANG, $help);
my ($SPACEID, $CTRY, $OPR, $CDF, $REST, $NOCUST, $NOSIGN, @FIELDS);

my %OPRTBL = ( Customized => "CUS",
               Mobilkom   => "MOB",
               Optus      => "OPT",
               'T-Mobile' => "TMO",
               Telenor    => "TEL",
               Vodafone   => "VOD",
               Swisscom   => "SWI",
               Wind       => "WIN",
               IAM        => "IAM",
               Meditel    => "MED",
               Movistar   => "MOV",
             );
               
               


## Routines
#
sub create_dir($);
sub build_dev_eval();
sub print_msg($);
sub copyToUnfShare();
sub main();

main();


#----------------------------------------------------------------------#
# Subroutine    : main
# Purpose       : Main routine. prepare environments, variables, and
#                 loop thru each vendor and call its vmain.pl
# Parameters    :
# Returns       : 1 successful operations, otherwise 0 fail
#----------------------------------------------------------------------#
sub main() {

    ## Defined variables
    #

    GetOptions ('bsplb=s' => \$BSPLB, 'prodlb=s' => \$PRODLB, 'mktfile=s' => \$MKTFILE, 'nocust' => \$NOCUST,
                'nosign' => \$NOSIGN, 'help|?' => \$help);

    if ( ! $BSPLB or defined $help ) {
       usage();
    }

    $VIEW = "Z:\\" . `cleartool pwv -short`;
    chop($VIEW);
    $BLDSCRIPTS = "$VIEW\\USSV_Devtools\\cnh1012571_convergence_tools\\Scripts";

    # Clean dirs in builtsw before start of build
    if (-e $TMPDELLANG) { system("rmdir /q/s $TMPDELLANG"); }
    if (-e $TMPDELPROD) { system("rmdir /q/s $TMPDELPROD"); }
    if (-e $TMPDELCAB) { system("rmdir /q/s $TMPDELCAB"); }
    
    ## Read market.txt or user defined file to %Market
    #
    open(INFILE, $MKTFILE) or die "Can't open $MKTFILE\n";
    LINE: while(<INFILE>) {
       next LINE if /^#/;   # skip comments
       next LINE if /^$/;   # skip blank lines
       
       ($SPACEID, $REST) = split /:\s*/, $_, 2;
       @FIELDS = split ' ', $REST;
       $Market{$SPACEID} = [ @FIELDS ];
       ($CTRY, $OPR, $LANG, $CDF) = split(" ", $REST);

      # process this market
      print "\n\n\n********************************************************************************\n";
      print "Copyright (c) 2009, Sony Ericsson All Rights Reserved.\n";
      print "--------------------------------------------------------------------------------\n";
      print "Building 1551 apps + $LANG BSP $BSPLB + $SPACEID:$CTRY:$OPR:$LANG:$CDF\n" if (not defined $NOCUST);
      print "Building 1551 apps + $LANG BSP $BSPLB with no customization\n" if (defined $NOCUST);
      print "  on machine $COMPUTERNAME with $OS\n";
      print "  using view $VIEW\n";
      print "  as user $USERNAME\n";
      print "  on $DATETIME\n";
      print "********************************************************************************\n";

      if (not defined $NOCUST) {
         my $error = system("stagecabs --prodlb $PRODLB --ctry $CTRY --opr $OPR --lang $LANG --custlb $CDF");
         if ($error) { die "\nError: $error\n"; }

         if (not defined $NOSIGN) {
            $error = system("generateSDR.bat /bsplb:$BSPLB /prodlb:$PRODLB /country:$CTRY /opr:$OPRTBL{$OPR} /lang:$LANG /sign:1");
            if ($error) { die "\nError: $error\n"; }
         } else {
            $error = system("generateSDR.bat /bsplb:$BSPLB /prodlb:$PRODLB /country:$CTRY /opr:$OPRTBL{$OPR} /lang:$LANG");
            if ($error) { die "\nError: $error\n"; }         
         }

         # Also build dev_eval if United_Kingdom (spaceid 1230-2799)
         # build_dev_eval() if ($SPACEID =~ m/1230-2799/);
      } else {
         my $error = system("stagecabs --prodlb $PRODLB --nocust");
         if ($error) { die "\nError: $error\n"; }

         $error = system("generateSDR.bat /bsplb:$BSPLB /prodlb:$PRODLB /country:$CTRY /opr:$OPRTBL{$OPR} /lang:$LANG /nocust:1");
         if ($error) { die "\nError: $error\n"; }
      }
    }
    close(INFILE);    

    # Copying to unofficial shared folder
    copyToUnfShare();

    print "\nbuild finished: ";
    system("time /t\n");

}

sub copyToUnfShare() {
    print_msg("Copying to unofficial shared folder...");
    my $unfdlvr = "$CONVERGENCE_UNFPROD\\" . "CRH1062001_" . "$PRODLB";
    
    # do not clopper existing folder in share
    if (-e $unfdlvr) { die "\nError: $unfdlvr already exist\n"; }
    
    my $sprod    = "$unfdlvr\\PROD";
    my $sdev     = "$unfdlvr\\DEV";
    my $sdeveval = "$unfdlvr\\DEV_EVAL";
    my $scab     = "$unfdlvr\\CAB";
    my $smbn     = "$unfdlvr\\MBN";
    my $slang    = "$unfdlvr\\CAB\\langs";
    # copy to unofficial site
    if (! -e $sprod) { create_dir($sprod); }
    if (! -e $sdev)  { create_dir($sdev); }
    if (! -e $scab)  { create_dir($scab); }
    if (! -e $smbn)  { create_dir($smbn); }
    if (! -e $slang) { create_dir($slang);}
    system("xcopy /v/f/s/i   $TMPDELCAB $scab >NUL");
    system("xcopy /v/f/s/i   $TMPDELLANG $slang >NUL");
    system("xcopy /v/f/s/i   $TMPDELPROD $sprod");
    system("xcopy /v/f/s/i   $TMPDELDEV $sdev");
    system("xcopy /v/f/s/i   $TMPDELDEVEVAL $sdeveval");
    # copy mbn & hex files
    system("xcopy /v/f/i   $TMPDELIMG\\*.mbn $smbn");
    system("xcopy /v/f/i   $TMPDELIMG\\*.hex $smbn");
    
    system("copy $BLDSCRIPTS\\build.log $unfdlvr");
    system("copy $BLDSCRIPTS\\$MKTFILE $unfdlvr");
}

#----------------------------------------------------------------------#
# Subroutine    : build_dev_eval
# Purpose       : build UK customization dev_eval
# Parameters    : 
# Returns       :
#----------------------------------------------------------------------#
sub build_dev_eval() {
   my $error;

   print_msg("Building dev and dev_eval");
   $error = system("generateSDR.bat /bsplb:$BSPLB /prodlb:$PRODLB /country:$CTRY /opr:CUS /lang:$LANG /config:dev");
   if ($error) { die "\nError: $error\n"; }
   $error = system("generateSDR.bat /bsplb:$BSPLB /prodlb:$PRODLB /country:$CTRY /opr:CUS /lang:$LANG /config:dev_eval");
   if ($error) { die "\nError: $error\n"; }
}


#----------------------------------------------------------------------#
# Subroutine    : print_msg
# Purpose       : prints message
# Parameters    : msg - message to print
# Returns       :
#----------------------------------------------------------------------#
sub print_msg($) {
   my ($msg) = @_;
   print "\n\n---------------------------------------------------------------------\n";
   print "$msg\n";
   print "---------------------------------------------------------------------\n";
}

#----------------------------------------------------------------------#
# Subroutine    : creat_dir
# Purpose       : Create delivery directory
# Parameters    : Full path directory location to create
# Returns       : 1 successful operations, otherwise 0 fail
#----------------------------------------------------------------------#
sub create_dir($) {
    my ($dir) = @_;
    my $result = system("mkdir $dir");
    return $result;
}

#----------------------------------------------------------------------#
# Subroutine    : usage
# Purpose       : prints usage of this script
# Parameters    :
# Returns       :
#----------------------------------------------------------------------#
sub usage() {
    print "Unknown options: @_\n" if (@_);
    print "usage: moabuild --bsplb bsp_label --prodlb product_label [--mktfile custfile] [--nocust] [--nosign] [--help|-?]\n";
    print "   ex: moabuild --bsplb R1AA042 --prodlb R1AA054\n\n";
    exit;
}

__END__
:endperl

