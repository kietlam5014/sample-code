&unres;

sub unres {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -rec -cview -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool unres \"$co\" ");
   }
   close(COFILE);
}