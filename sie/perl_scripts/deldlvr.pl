###########################################################################
##
## Copyright (c) 1999, Siemens Information and Communication Networks, Inc.
## All Rights Reserved.
##
## System:       HiNet RC 3000
## Component:    bld
## SubComponent: tools
## Module:
##
## Description:  Checkouts and deletes files in "deliver" directory, except
##               files specified in RETAINFILE.
##
## Revision History:
##
## Date         Author  Ver Description
##
## 04/12/1999   kietl     1 Creation
## 04/13/1999   kietl     2 Removed user interaction for automation.
## 04/22/1999   kietl     3 Added option to checkout reserved or unreserved.
## 04/30/1999   kietl     4 Added RETAINFILE which contains the files that
##                          is to be skipped when processing the checkout & delete.
## 05/06/1999   sinotte   9 Add text_nl.properties
## 05/07/1999   kietl    10 Added -ndata argument to checkout
##
###########################################################################
#
# Usage: deldlvr [drive:]path
#

if (@ARGV != 2) {
   print("Usage: deldlvr -{res|unres} [drive:]path\n");
   exit 0;
}

#
## o RETAINFILE:  use to list all the files to be skipped.  Add dir/file here
##                to be skipped.
##
#
@RETAINFILE = ('\top\mgmt\deliver\classes\symantec_subd.jar',
               '\top\mgmt\deliver\classes\symantec_usra.jar',
               '\top\client\deliver\win32\lib\text_de.properties',
               '\top\client\deliver\win32\lib\text_nl.properties',
               '\top\client\deliver\win32\lib\text_en.properties',
               '\top\client\deliver\win32\lib\text_es.properties',
               '\top\client\deliver\win32\lib\text_fr.properties',
               '\top\client\deliver\win32\lib\text_it.properties',
               '\top\license\deliver\classes\licenseClient.jar',
               '\top\acdsrv\deliver\classes\configAPI.jar',
               '\top\acdsrv\deliver\classes\configApplet.jar',
               '\top\acdsrv\deliver\classes\configServlet.jar',
               '\top\jtapi\deliver\testclient.jar',
               '\top\bld\deliver'
               );


$file1 = 'c:\temp\tmpfile1';      # Contains all path with 'deliver'
                                  # directory name.
$file2 = 'c:\temp\tmpfile2';      # Contains all path:filenames.
$topdir = @ARGV[1];               # [drive:]path
$prm = @ARGV[0];                  # -{res|unres}

chdir($topdir) || die "Cannot chdir to $topdir";

# Searches from $topdir directory and all its subdirectories for the
# directory name 'deliver'. Stores result in $file1.

print("Extracting deliver directories to tempfile.  This will take about a minute...\n");
system("dir /b/s /ad deliver > $file1");

open(TXTFILE1, $file1);
while (<TXTFILE1>) {
   chop($_);
   $path = $_;
   chdir($_) || die "Cannot chdir $_";
   system("dir /b/s /a-d > $file2");
   open(TXTFILE2, $file2);
   while (<TXTFILE2>) {
      chop($_);
      if (&isIn($path, $_) != 1) {
         print("Checking out and removing: $_\n");
#         system("cleartool co $prm -ndata -nc $_");
      }
   }
   close(TXTFILE2);
}
close(TXTFILE1);


# #################################################################################### #
# Check and return 1 if a giving file is in RETAINFILE.
# #################################################################################### #
sub isIn {
   local ($path, $pathfile) = @_;
   $tmppath = $pathfile;
   $pathfile =~ s#.*\\##;

   foreach (@RETAINFILE) {
      print "Match!!\n" if ($path eq $_);
      $_ =~ s#.*\\##;                  # Gets filename only.  Trash its path.
      return 1 if ($_ eq $pathfile);
   }
   return 0;
}

unlink($file1);
unlink($file2);
