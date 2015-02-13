# Author: Kiet Lam
# Version: 1.2
#
# History
#
###############################################################

$RM = @ARGV[0];
$RM =~ tr/A-Z/a-z/;

&unco;

sub unco {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      if ($RM eq "rm") {
        system("cleartool unco -rm \"$co\"");
      } else {
        system("cleartool unco -keep \"$co\"");
      }
   }
   close(COFILE);
}
