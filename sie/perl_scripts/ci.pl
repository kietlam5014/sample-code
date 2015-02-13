&co;

sub co {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      chop($co);
      system("cleartool ci -nc -ptime \"$co\" ");
   }
   close(COFILE);
}
