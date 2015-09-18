# Author: Kiet Lam
#
# Description:	Recursively checked out files unres from current
#		directory.
#
# Date		Description
# 01/30/03	Creation
###############################################################
&co;

sub co {
   local $co;
   unless (open(COFILE, sprintf("cleartool ls -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool co -nc -unres -ver \"$co\" ");
   }
   close(COFILE);
}
