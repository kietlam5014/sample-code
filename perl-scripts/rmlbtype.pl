# Scripts to remove label type

open(TF, "lbtypeRemove.txt");
while ($lbname = <TF>) {
   chop($lbname);
   system("cleartool unlock lbtype:$lbname");
   system("cleartool rmtype -rmall -force lbtype:$lbname");
}

close(TF);
