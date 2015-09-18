###########################################################################
##
## Description: Read a list of files containing <CC_HINET_VRSN> in its
##              content, checkouts and replaces <CC_HINET_VRSN> with
##              ClearCase BIND label.
##
## Revision History:
##
## Date         Author  Ver Description
##
## 05/05/1999   kietl     1 Creation
##
###########################################################################
#
# Usage: ccperl vrsnupdate.pl BIND
#

if (@ARGV != 1) {
   print("Usage: ccperl vrsnupdate.pl BIND\n");
   exit 0;
}

$FILE1 = 'top\bld\dat\version_files.txt';      # list of path files with <CC_HINET_VRSN>
$CCVRSN = @ARGV[0];   # BIND

open(TXTFILE1, $FILE1);
while (<TXTFILE1>) {
   @fields = split(/:/,$_);
   $path = $fields[0];
   $filename = $fields[1];
   $_ =~ s/://;
   open(TXTFILE2, $_) || die "Error opening $_\n";
   $FILE2 = "${path}tmpfile.tmp";
   open(OUTFILE, ">$FILE2");
   while (<TXTFILE2>) {
      s/\<CC_HINET_VRSN>$/$CCVRSN/g;
      print OUTFILE $_;
   }

   close(OUTFILE);
   close(TXTFILE2);

   system ("cd \"$path\" && copy tmpfile.tmp $filename");
   system ("cd \"$path\" && del tmpfile.tmp");

}
close(TXTFILE1);
