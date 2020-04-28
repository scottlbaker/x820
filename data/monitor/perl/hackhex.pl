
#####################################################
# Hack a Hex file
# This script removes the first 100h locations from
# the hex file and adds a $$ termination indicator
#####################################################

use strict;
use warnings;

my $file;   # file name
my $size;   # file size in bytes

if ($#ARGV == 1) {
    $file = $ARGV[0];
    $size = $ARGV[1];
} else {
    print ("\nUSAGE:   hackhex <filename> <filesize>\n");
    exit 1;
}

if (-f $file) {
    open(FP1, "< $file") || die("Cannot open $file: $!");
} else {
    print ("ERROR: $file is not a file\n");
    exit(-1);
}

my @outx = ();
my $line;
my $count = 0;

my @lines = <FP1>;
close(FP1);

foreach $line (@lines) {
    if (($count > 255) && ($count < $size)) {
        push (@outx, $line);
    }
    $count++;
}

$line = "\$\$\n";
push (@outx, $line);

open(FP1, ">$file") || die "Cannot open $file for writing";
print FP1 @outx;
close(FP1);

