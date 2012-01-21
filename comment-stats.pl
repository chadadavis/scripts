#!/usr/bin/env perl
# Calculates stats on code. (works on perl, bash, sh, R, C/C++, Java)
# Namely, how many comment and code lines are contained in a file
# Understands documentation blocks from:
# POD (Perl), JavaDoc (Java), bvmutils (R), doxygen (C/C++)

our $all;        # every line in the file(s)
our $blank;      # whitespace lines
our $doc;        # parsable documentation 
our $comment;    # programmer comment
our $nonblank;   # non-blank lines, i.e. code or comments or documentation
our $noncomment; # code, the meat

my $nest;

# Single-line comments, beginning with // or # or ; 
# my $comment_char = shift || "(\/\/|#|;)";
my $comment_char = "(\/\/|#|;)";

# TODO
# Type of comments checked should depend on file type (check file magic)
# Add fortran comments (line begins with 'c')

while (<>) {
    $all++;
    if (/^\s*$/) { $blank++; next; }
    $nonblank++;
    if (/^\s*${comment_char}/) { $comment++; next; }

    # PDOC (Perl) doc?
    comment_block('^=', '^=cut', \$doc);
    # bvmutils (R) doc?
    comment_block('^\s*\.doc', '^\"', \$doc);
    # JavaDoc?
    comment_block('^\s*\/\*\*', '\*\/', \$doc);
    # Doxygen?
    comment_block('^\s*\/\*\!', '\*\/', \$doc);

    # C++/Java block comment? (counted as comment, not documentation)
    comment_block('^\s*\/\*', '\*\/', \$comment);

    # Otherwise it's meat
    $noncomment++;
}

die("No files found\n") unless $all;

printf 
    "Lines: %d\n" . 
    "  Blank:\t %6d / %6d (%5.2f\%)\n" . 
    "  Non-blank:\t %6d / %6d (%5.2f\%)\n" . 
    "    Docs:\t %6d / %6d (%5.2f\%)\n" .
    "    Comments:\t %6d / %6d (%5.2f\%)\n" . 
    "    Code:\t %6d / %6d (%5.2f\%)\n",
    $all,
    $blank, $all, 100 * $blank / $all,
    $nonblank, $all, 100 * $nonblank / $all,
    $doc, $nonblank, 100 * $doc / $nonblank,
    $comment, $nonblank, 100 * $comment / $nonblank,
    $noncomment, $nonblank, 100 * $noncomment / $nonblank,
    ;

sub comment_block {
    my ($start, $end, $counter) = @_;
    our ($all, $blank, $nonblank);

    if (/${start}/) {
        ${$counter}++; # for the starting line
        # Don't continue if the multi-line comment also ends on the current line
        return if /${end}/;
        # Otherwise read the rest of the comment block
        while ($nest = <>) {
            $all++;
            if ($nest =~ /^\s*$/) { $blank++; next; }
            $nonblank++;
            if ($nest =~ /${end}/) { ${$counter}++; last; }
            ${$counter}++;
        }
        next;
    }
} # comment_block

