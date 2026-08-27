# Script to check unprefixed units
# TODO: Delete this file after all units are prefixed

use strict;
use warnings;
use v5.38.2;

opendir my $dh, ".";

say for grep {
  -f
  && ($_ !~ /^P92/)
  && ($_ =~ /\.PAS$/) 
} readdir $dh;

closedir $dh
