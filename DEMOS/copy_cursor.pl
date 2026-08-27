use strict;
use warnings;
use v5.38.2;

use File::Copy;
use File::Spec::Functions;

my $src_file = catfile("SIMPLE", "CURSOR.BMP");

opendir my $dh, $dest_dir_path;

my @dirs = grep { $_ ne "." && $_ ne ".." } readdir $dh;

closedir $dh;

for (@dirs) {
  my $test_cursor = catfile(
    # ".",  # DEMOS
    "..", "TESTS",  # ..\TESTS
    $_, "CURSOR.BMP");

  next if $test_cursor eq $src_file;

  if (-f $test_cursor) {
    say "Replacing ".$test_cursor;

    copy $src_file, $test_cursor
  }
}
