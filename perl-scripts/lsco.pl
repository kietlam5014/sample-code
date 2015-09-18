&lsco;

sub lsco {
   local $co;
   unless (open(COFILE, sprintf("cleartool lsco -cview -rec -short . |"))) {
      return "";
   }
   while (<COFILE>) {
      $co = $_;
      print $co;
   }
   close(COFILE);
   return $co;
}