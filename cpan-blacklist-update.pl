#!/usr/bin/env perl
# Run this in ~/.cpan/prefs and feed it a list of distro names that are blacklisted
use Modern::Perl;
use File::Slurp qw/slurp/;
# Template contains a %s where the distro name goes
my $template = slurp("blacklist.template");
while (<>) {
    chomp;
    next unless /^[a-zA-Z0-9_:-]+$/;
    # Allow :: separated names too
    s/::/-/g;
    open my $fh, '>', "$_.yml";
    print $fh sprintf $template, $_;
    close $fh;
}
