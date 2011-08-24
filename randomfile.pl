#!/usr/bin/perl

my $dir = shift || '.';
my @files = `find $dir -type f`;
srand(time|$$);
print $files[int(rand(@files))];

