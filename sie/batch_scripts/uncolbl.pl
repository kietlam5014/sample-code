# Author: Kiet Lam
# Version: 1.0
#
# History
# testing
#
###############################################################

$BIND = @ARGV[0];

&unco($BIND);

sub unco {
   local ($bind) = @_;
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool unco -rm \"$co\"");
      system("cleartool mklabel -rep $bind \"$co\"");
   }
   close(COFILE);
}
