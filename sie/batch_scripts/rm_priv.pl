# Author: Cheri Lee
# Version: 1.0
#
# History
# 10/15/2003   remove view private files and dirs.
#
###############################################################

&rmpriv;

sub rmpriv {
   local $rmpriv;
   unless (open(COFILE, sprintf("cleartool lspriv |"))) {
      return "";
   }
   while (<COFILE>) {
      $rmpriv = $_;
      chop($rmpriv);
      print "$rmpriv \n";
      system("del /q \"$rmpriv\"");
      system("rmdir /s/q \"$rmpriv\"");
   }
   close(COFILE);
}
