#!/usr/bin/env perl 

=head1 NAME

pdb2gif.pl - Reads PDB file and create animated GIF showing the molecule rotating.

=head1 SYNOPSIS

perl pdb2gif.pl <file.pdb> -x -y -steps 30 -secs 5 -size 200x200 -r rasmol-classic

=head1 DESCRIPTION

Reads the given PDB file and uses Rasmol and ImageMagick to create an animated GIF of the molecule rotating around on or more axes. Uses the "cartoon" representation of Rasmol with the color by "group" option. The number of axes about which the molecule is rotated can be selected, the number of frames to generate as well as the total duration of the animation are configurable.

=head1 OPTIONS

=head2 -verbose | -v

Print extra debugging information.

=head2 -help | -h | -?

Print this help.

=head2 -x | -y | -z

Which axes of rotation to enable. Any combination of -x -y or -z may be enabled. Rotation is always in the positive direction about the axes. See the Rasmol documentation for further information. 

=head2 -size

The size of the output image file. Defaults to 150x150.

=head2 -steps

Number of frames (pictures) in the final animation file. Default 30 frames/steps.

=head2 -seconds | -secs

Number of seconds for the complete animation to run. This simply inserts larger pauses between displays of the frames, it does not make the animation appear "smoother". For that increase the "-steps" option. Default 5 seconds.

=head2 -rasmol | -r

Rasmol program, if it's not in your PATH.

NB if using a newer linux, you might need to pass 

 -r rasmol-classic 

here, as the newer versions seem to handle scripting differently.


=head1 BUGS

o Rasmol does not allow GIF file to be created with a given size. So, all of the files have to be resized as they are processed into the animation. This slows the program significantly. 

o Reducing the bitdepth of the generated GIFs may improve performance. 

o GIF transparency doesn't seem to work correctly, even with the 'set transparent' option set in Rasmol. ImageMagick can make a color transparent during subsequent conversion. The presents the problem, that animations created from images containing transparent colors don't clear the display between renderings of frames, which results in a blur. Figuring out how to execute some sort of 'clear' between frames in the animation would allow images with black transparent to save on file size. 

o Rounding causes problems, such that the number of frames doen't cause a complete rotation back to the starting frame, depending on the number of 'steps' chosen. Sometimes it works, sometimes it doesn't. Currently an empirically derived error estimator is being used, but it's not clear whether this is sufficient.

=head1 REVISION

$Id: pdb2gif.pl,v 1.4 2005/01/22 11:43:26 uid1343 Exp $

=cut

################################################################################

use strict;
use warnings;

use Getopt::Long;
use File::Spec;
# Default command line options
my %opts = (verbose => 0);
GetOptions(\%opts,
           'verbose|v',
           'help|h|?',
           'size=s',
           'steps=s',
           'seconds|secs=s',
           'rasmol|r=s',
           'x',
           'y', 
           'z',
           ) or usage();
# Show help if command line args. weren't what was expected
usage() if $opts{'help'};
usage() unless @ARGV;
$::VERBOSE = $opts{'verbose'};


my $rasmol = $opts{'rasmol'} || 'rasmol';
# Default size of output image
my $size = $opts{'size'} || "150x150";
# Number of seconds before the GIF repeats from 1st frame again
my $secs = $opts{'seconds'} || 5;
# Number of frames in the final animtion
my $steps = $opts{'steps'} || 30;
# Number of axes of rotation
my $axes = 0;
map {$axes++ if defined $opts{$_} } qw(x y z);
$axes or usage();
# Number of degrees to reach the next step/frame, i.e. size of each rotation
# TODOBUG
#my $degrees = (($axes > 1 ? 540.0 : 360.0) / $steps) / $axes;
my $degrees = ((180.0 + $axes * 180.0) / $steps) / $axes;
# Time-delay (pause) for each frame of the animation
my $delay = $secs * (100.0 / $steps);
# PDB file to process
my $file = shift;
$file = File::Spec->rel2abs($file);
die "File not found: $file\n" unless -e $file;

# The parameter could be a PDB ID or the path to a PDB file
#$file = pdb_file($file) unless -f $file;

sub usage {
    system("pod2text $0");
    exit 1;
}

my $tmpdir = `mktemp -d -t pdb2gif.XXXXX` || '.';
chomp $tmpdir;
print STDERR "tmpdir:$tmpdir:" if $::VERBOSE;

# Save current working directory
my $pwd = $ENV{PWD};
chdir $tmpdir or 
    die("Cannot chdir to $tmpdir ($!)\n");

`cp $file .`;
$file = <$tmpdir/*>;

print "size:$size:secs:$secs:steps:$steps:axes:$axes:degrees:$degrees:" . 
    "delay:$delay:file:$file:\n" if $::VERBOSE;

################################################################################

# Basic Rasmol commands
my $script = <<EOF;

#background [0,0,0]
#set ambient 40
#set specular on
#set specpower 8
#reset
#slab off
#set axes off
#set boundingbox off
#set unitcell off
#set bondmode and
#dots off
# Avoid Colour Problems!
#select all
#colour bonds none
#colour backbone none
#colour hbonds none
#colour ssbonds none
#colour ribbons none
#colour white
# Atoms
#select all
#spacefill off
# Bonds
wireframe off
# Ribbons
#set strands 5
#set cartoon on
#set cartoon 100
#ribbons 720
# Backbone
#select all
#backbone off
# Labels
#labels off
# Monitors
#monitors off
#ssbonds off
#hbonds off
cartoons
colour chains
set write on
set transparent on

EOF

################################################################################

# Pipe script into rasmol

 open RASMOL, "|$rasmol -nodisplay >/dev/null" or 
#open RASMOL, "|$rasmol " or 
    die "Can't start rasmol. Is it in your PATH?\n$!\n$@\n";
# Display axes, when debugging
print RASMOL "set axes on\n" if $::VERBOSE;
# Clear display and load PDB file
# print RASMOL "load pdb \"$file\"\n";
print RASMOL "load  \"$file\"\n";
# Send basic script commands (coloring, etc.)
print RASMOL $script;

# TODOBUG
# Don't know why this is necessary, but as the number of steps increase, the
#   the number of extra frames in the animation goes up, but only when more than
#   one axis of rotation is selected.
# The following mesurements have been made:
#
# $axes | $steps | $error +/- 1
# 1       10       0
# 1       20       0
# 1       50       0
# 2       15       1
# 2       35       2
# 2       65       4
# 2       85       4       
# 3       35       5
# 3       50       8
# 3       65       10
# 3       85       12

my $error = 0;
$error = $steps / 15 if $axes == 2;
$error = $steps / 7  if $axes == 3;

my $imgbase = "$file.$$.";
my $imgext = ".ppm";

for (1 .. $steps - $error  ) {
    $_ = sprintf "%03d", $_;

    # Save one static image (one frame of animation)
#     print RASMOL "write $file.$$.$_.gif\n";
    print RASMOL "write ${imgbase}${_}${imgext}\n";
    # Rotate in all the necessary directions (x y z) by the necessary number of
    #   degrees
    for (qw(x y z)) {
        print RASMOL "rotate $_ $degrees\n" if $opts{$_};
    }
}
    
print RASMOL "exit\n";
close RASMOL;


print STDERR "Converting $steps files ...\n";
# First convert the GIFs to the smaller PNG format, resizing along the way
my $convert = 
    "for i in ${imgbase}*${imgext};" . 
    "do convert -resize $size \$i \$i.png;" .
    "done";
#print STDERR "$convert\n";
#`$convert`;

# Now feed the smaller files back in, to be converted to an animated GIF
# $convert = "convert -delay $delay $file.$$.*png $file.$$.gif";
#$convert = "convert -delay $delay ${imgbase}*${imgext} ${imgbase}gif";
$convert = "convert -resize $size -delay $delay ${imgbase}*.ppm ${imgbase}gif";
print "$convert\n" if $::VERBOSE;
`$convert`;

# Delete static intermediate GIF files that were created
print STDERR "Cleaning up intermediate files ... \n" if $::VERBOSE;
`rm $file.$$.*.*` unless $::VERBOSE;
print "$file.$$.gif\n";

# Return to start dir.
chdir $pwd or 
    print STDERR "Cannot chdir to $pwd ($!)" and exit;

exit;

################################################################################

