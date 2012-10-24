#!/usr/bin/env sh

export DISPLAY=":0.0"
export HOME=/home/chdavis
export XAUTHORITY=$HOME/.Xauthority
# Run this in the background, otherwise udev doesn't finalize the adding of the device
# Device needs to be installed before xmodmap can work on it
sleep 1 && /usr/bin/xmodmap $HOME/.xmodmaprc &
