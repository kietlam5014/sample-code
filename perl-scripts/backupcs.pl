# To generate "seasdie_views.txt":
#    cleartool lsview -short -host Seaside > views.txt
#
open(INFILE, "views.txt");
while (<INFILE>) {
   chop($_);
   print "ct catcs $_\n";
   system("cleartool catcs -tag $_ > a:\\$_.cs");
}

close(INFILE);
