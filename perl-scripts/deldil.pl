# 04/12/99 Kiet Lam


# Global Variables
$file = "deldir.txt";

# Searches from current directory and all its subdirectories for the
# name deliver.  Stores result in deldir.txt.
# system ("dir /b /s deliver > deldir.txt");

# Opens textfile for reading.
open(TXTFILE, $file);

while (<TXTFILE>) {
   chdir $_ || die "Can't cd \n";
   system("cd z:");
}

close(TXTFILE);
