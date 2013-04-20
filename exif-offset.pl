#!/usr/bin/env perl

# Notes

use Image::ExifTool qw(:Public);
use Date::Manip;

# Usage: 
# Increment/decrement dates by X years, months, days, hours, minutes, seconds
# Intended to be used on images containing EXIF data from digital cameras
# Original files are saved with *.bak extension
sub usage {
    print STDERR 
        "Usage:\n\n $0 [+-][0-9]+[y|m|d|h|min|s] <files ...>\n\n",
        ;
    exit;
}

# How much to shift the date/time by, e.g. : 
# Years (Y), Months (M), Days (D), Hours (H), Minutes (min), Seconds (S)
my $offset = shift @ARGV;
# The name of the field containing the date. 
# Format is e.g.: "2006:12:22 23:50:49"
my $tag = "DateTimeOriginal";
# Temp. var.
my $success;

usage() unless @ARGV;

# Shift date of each file by same offset
for my $file (@ARGV) {

    # Get hash of meta information tag names/values from an image
    my $info = ImageInfo($file);
    # Create a new Image::ExifTool object
    my $exifTool = new Image::ExifTool;
    # Extract meta information from an image
    $success = $exifTool->ExtractInfo($file);
    unless ($success) {
        print STDERR "Couldn't read EXIF data in file: $file\n";
        next;
    }

    # Get the value of a specified tag
    my $datestr = $exifTool->GetValue($tag);
    print STDERR "old:$datestr:\n";
    # Remove ':' and ' ' in order to be able to parse date
    $datestr =~ s/[: ]//g;
    # Shift date by given offset
    my $ndate = DateCalc($datestr, $offset);
    # Skip if no (valid) offset given
    next unless $ndate;

    # Output date into EXIF-compatible format
    my $ndatestr = UnixDate($ndate, "%Y:%m:%d %H:%M:%S");
    print STDERR "new:$ndatestr:\n";

    # Set a new value for a tag
    $success = $exifTool->SetNewValue($tag, $ndatestr);
    unless ($success) {
        print STDERR "Failed to set $tag to $ndatestr on $file\n";
        next;
    }

    # Write new meta information to a file
    rename $file, "${file}.bak";
    $success = $exifTool->WriteInfo("${file}.bak", $file);
    unless ($success) {
        print STDERR "Failed to write $file\n";
        next;
    }

} # while

