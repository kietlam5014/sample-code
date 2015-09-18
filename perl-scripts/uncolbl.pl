# Author: Kiet Lam
# Version: 1.0
#
# History
#
###############################################################

&unco;

sub unco {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool unco -rm \"$co\"");
      system("cleartool mklabel -rep HINET_PXIV_3.0.584-B.001.017 \"$co\"");
      system("cleartool mklabel -rep HINET_PXIV_3.0.584-0 \"$co\"");

   }
   close(COFILE);
}
