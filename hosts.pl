#!/usr/bin/env perl

# Get IP addresses, 
# Ping for a couple seconds, 
# Then gather the non-duplicate results
my $cmd = 
    "ping -c 2 -b 255.255.255.255 | " . 
    "grep from | " . 
    "cut -f 4 -d ' ' | " . 
    "sort | " . 
    "uniq";

# Extract IPs from the formatted output
my @ips = map { /(\d+\.\d+\.\d+\.\d+)/ } `$cmd`;

print "ips: @ips\n";

# Get rid of private addresses
#my @ips = grep { ! /^10\./ } @ips;
my @ips = grep { ! /^127\./ } @ips;
my @ips = grep { ! /^169\.254\./ } @ips;
my @ips = grep { ! /^172\.16\./ } @ips;
my @ips = grep { ! /^192\.168/ } @ips;

for (@ips) {
    my $line = `host $_`;
    chomp $line;
    my @tokens = split(/\s+/, $line);
    my $host = pop @tokens;

    if ($host) {
        push @hosts, $host;
        print "$host ";
    }
}

