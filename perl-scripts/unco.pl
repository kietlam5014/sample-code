&unco;

sub unco {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool unco -rm \"$co\" ");
   }
   close(COFILE);
}