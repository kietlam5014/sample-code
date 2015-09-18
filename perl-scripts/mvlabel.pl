@LB = (
'abc',
'def'
);

$FILE = ".";

foreach $lb (@LB) {
   system("cleartool mklabel -rep $lb $FILE ");
}
