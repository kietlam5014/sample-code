&rmlb;

sub rmlb {
   local $fp;
   unless (open(LSFILE, sprintf("cleartool ls -rec -short . |"))) {
      return "";
   }
   while (<LSFILE>) {
      $fp = $_;
      chop($fp);
      system("cleartool rmlabel HINET_BIND_2.5.016-N.001.007 \"$fp\" ");
   }
   close(LSFILE);
}