use strict;
use warnings;
use v5.38.2;

use File::Copy;

opendir my $dh, ".";

say for grep { -d && ($_ ne ".") && ($_ ne "..") } readdir $dh;

# copy "SIMPLE/CURSOR.BMP"