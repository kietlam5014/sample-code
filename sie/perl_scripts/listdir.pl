$dir = "R:\\top\\install\\bind\\InstallShield\\HiNetRC3000\\File Groups";
print "Files in $dir are:\n";
opendir(BIN, $dir) or die "Can't open $dir: $!";
while (defined ($file = readdir BIN) ) {
   next if $file =~ /^\.\.?$/;  # skip . and ..
   next if (-s "$dir\\$file") == 44;
   print "$file\n";
}
