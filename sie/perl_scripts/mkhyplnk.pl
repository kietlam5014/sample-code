# ################
# Global Vars
# ################
%gFile = ();
$makef;

&getFiles;

foreach $n (@gFile) {
   &mkhlink($n);
}


sub mkhlink {
   my ($dfile) = @_;
   local $line = 0;
   unless (open(TF, sprintf("cleartool catcr -short $dfile |"))) {
      return "";
   }
   while (<TF>) {
      if(/.*mak|makefile/) {
      $line += 1;
      $makef = $_;
      }
   }
   close(TF);

   # Print files which have too many makefiles
   print "\n****** $dfile\n" if ($line > 3);

   $makef =~ s/@.*//;  # Discard everything after the first @

   chop($dfile);
   chop($makef);
   if ($line <= 3) {
      print("cleartool mkhlink -nc makefile $dfile@@ $makef@@\n");
      system("cleartool mkhlink -nc makefile $dfile@@ $makef@@\n");
   }
}

sub getFiles {
   unless (open(TF, sprintf("cleartool ls -short -nxname . |"))) {
      return "";
   }
   while (<TF>) {
      push(@gFile, $_);
   }
   close(TF);
}   