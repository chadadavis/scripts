#!/usr/bin/env perl

# Watches the numer of lines in a file grow and monitors rate
# If a goal (numer of lines is given) and ETA will also be printed

use strict;
use warnings;
use Utils;

my $file = shift;
-r $file or die("Please provide path to (readable) file to be monitored\n");
my $goal = shift || 0;
my $resolution = shift || 30; # seconds

my $prev;
my $curr;
my $rate;
my @parts;

for ($prev=nlines($file); sleep($resolution); $prev=$curr) {
    $curr = nlines($file);
    # Enforce float arithmetic
    $rate = 1.0 * ($curr - $prev) / $resolution;
    next unless $rate;
    @parts = localtime();
    printf "%02d:%02d:%02d Rate: %10.3f /s", @parts[2,1,0], $rate;
    if ($goal) {
        my $lines = $goal - $curr;
        if ($lines < 0) {
            printf "\nLines: %10d\n", $curr;
            exit;
        }
        my $remain = $lines / $rate; 
        @parts = gmtime($remain);
        # Add days to hours field
        $parts[2] += $parts[7]*24;
        printf 
            "\tRemaining: lines: %10d , time: %02d:%02d:%02d", 
            $lines, @parts[2,1,0];
    }
    print "\n";
    $prev = $curr;
}

