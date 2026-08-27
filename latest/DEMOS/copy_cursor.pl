use strict;
use warnings;
use v5.38.2;

use File::Copy;
use File::Spec::Functions;

my $src_file = catfile("SIMPLE", "CURSOR.BMP");

opendir my $dh, ".";

for (grep { -d && ($_ ne ".") && ($_ ne "..") } readdir $dh) {
  my $test_cursor = catfile($_, "CURSOR.BMP");

  next if $test_cursor eq $src_file;

  if (-f $test_cursor) {
    say "Replacing ".$test_cursor

    # TODO: Actually copy the cursor
  }
}

closedir $dh

# copy "SIMPLE/CURSOR.BMP"