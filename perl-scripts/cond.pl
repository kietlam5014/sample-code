&cond;

sub cond {
   local $cond;
   unless (open(COFILE, sprintf("cleartool ls -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $cond = $_;
      chop($cond);
      system("cleartool co -ndata -nc \"$cond\" ");
   }
   close(COFILE);
}
