###########################################################################
##
## System:       Xperience
##
## Description:  Check makefile_accumulated.log for failure
##
## Revision History:
##
## Date     Author  Ver Description
##
## 01/29/03 kietl     1 Creation
## 05/05/03 kietl     3 Set correct log based on application
##-------------------------------------------------------------------------
## 02/25/04 kietl     1 Add Media Server option
## 02/26/04 kietl     2 Add check for other error
## 03/10/04 kietl     4 Add check for build log in xpr_installation\bld
## 03/12/04 kietl     6 Add check for build log in xpr_installation\bld for MCU
## 04/23/04 paynec    7 Add IWR mmtest log file
## 04/28/04 paynec    8 Add log files for IWR merge modules
## 05/07/04 kietl     9 Add check for build log in xperience_tools
## 06/24/04 kietl    10 check for comres_mmodules
## 07/02/04 kietl    11 check for omake: ERROR
## 08/03/04 kietl    12 Do not failed on VOB Locked
## 09/29/04 kietl    13 Add check for 'omake: Can't read makefile'
## 10/06/04 kietl    14 Add language pack support
## 11/26/06 kietl    16 Add toolbar
###########################################################################
#
# Usage: checkLogFail


if (@ARGV < 1) {
    $LOG = "\\xperience\\bld\\makefile_accumulated.log";

} else {
    if ($ARGV[0] =~ /BC/i) {
      $LOG = "\\xperience\\bld\\bc_accumulated.log";
    }
    elsif ($ARGV[0] =~ /APP/i) {
      $LOG = "\\xperience\\bld\\app_accumulated.log";
    }
    elsif ($ARGV[0] =~ /TBAR/i) {
      $LOG = "\\xperience\\bld\\toolbar_accumulated.log";
    }
    elsif ($ARGV[0] =~ /IMCU/i) {
      $LOG = "\\xpr_installation\\bld\\makefile_mcu_accumulated.log";
    }
    elsif ($ARGV[0] =~ /MCU/i) {
      $LOG = "\\mcu\\bld\\makefile_accumulated.log";
    }
    elsif ($ARGV[0] =~ /IIWR/i) {
      $LOG = "\\xpr_installation\\bld\\makefile_comres_accumulated.log";
    }
    elsif ($ARGV[0] =~ /MIWR/i) {
      $LOG = "\\xpr_installation\\bld\\comres_mmodules_accumulated.log";
    }
    elsif ($ARGV[0] =~ /IWR/i) {
      $LOG = "\\iwr\\cm\\makefile_accumulated.log";
    }
    elsif ($ARGV[0] =~ /IXPR/i) {
      $LOG = "\\xpr_installation\\bld\\makefile_accumulated.log";
    }
    elsif ($ARGV[0] =~ /XTOOLS/i) {
      $LOG = "\\xperience_tools\\bld\\makefile_accumulated.log";
    }
    elsif ($ARGV[0] =~ /ITBR/i) {
      $LOG = "\\xpr_installation\\bld\\makefile_toolbar_accumulated.log";
    }
    elsif ($ARGV[0] =~ /ILPK/i) {
      $LOG = "\\iwr\\cm\\langpack_accumulated.log";
    }
    elsif ($ARGV[0] =~ /LPK/i) {
      $LOG = "\\xperience\\bld\\langpack_accumulated.log";
    }
}

print "Checking $LOG for failure...\n";

open(INFILE, $LOG) || die "Cannot open $LOG\n";
while (<INFILE>) {
    if ($_ =~ m/Rebuild All:\s*([0-9]* succeeded, [0-9]* failed, [0-9]* skipped)/im)
    {
        $result = $1;
    }

    # Complicated match to look for a failed which _isn't_ '0 failed'
    if ($result =~ m/([1-9]\s+failed)/ ||
        $result =~ m/([0-9][0-9]+\s+failed)/)
    {
        # We have a failure
	print "$result\n";
        exit 1;
    }

    if ($_ =~ m/omake: Error: Lock on VOB database/m)
    {
        # Do not failed on this
        print "$_";
        exit 0;
    }

    if ($_ =~ m/omake: Shell/m)
    {
        # We have other failure
        print "$_";
        exit 1;
    }

    if ($_ =~ m/omake: Can't read makefile/m)
    {
        # can't read due to VOB lock?
        print "$_";
        exit 1;
    }

    if ($_ =~ m/omake: Error/m)
    {
        # We have other failure
        print "$_";
        exit 1;
    }
}
close(INFILE);
