use strict;
use warnings;
use v5.38.2;

my $compiler_path = "E:/fpc-msdos-i8086/fpc/bin/x86_64-win64/fpc.exe";
my @args = (
  "-Tmsdos",
  "-Pi8086",

  "-Fu..\\..\\UNITS",
  "-FuE:\\fpc-msdos-i8086\\fpcsrc\\rtl\\units\\msdos",
  "-FuE:\\fpc-msdos-i8086\\fpc\\units\\i8086-msdos\\rtl-console"
);

my $main_file = "GAME.PAS";

system $compiler_path, @args, $main_file
