#!/usr/bin/env perl
use LWP::Simple;
$url="http://apod.nasa.gov/apod";
($img)=get($url)=~m|SRC=\"(image/.*?\.jpg)\"|i;
getstore("$url/$img","$ENV{HOME}/Downloads/background.jpg");

