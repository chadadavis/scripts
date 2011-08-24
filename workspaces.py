#!/usr/bin/env python3
 
# author: Chad Versace <chad@chad-versace.us>
# date: 2001-11-24
# license: Public Domain
 
# Example Usage:
#     compiz-workspaces set x 4
#     compiz-workspaces set y 4
#     compiz-workspaces add x
#     compiz-workspaces add y
#     compiz-workspaces del x
#     compiz-workspaces del y
 
import sys
from subprocess import check_output, check_call
 
def axis_to_orientation(axis):
    if axis == "x":
        return "h"
    elif axis == "y":
        return "v"
    else:
        raise Exception()
 
def get_num_workspaces(axis):
    c = [ "dbus-send",
          "--print-reply",
          "--type=method_call",
          "--dest=org.freedesktop.compiz",
          "/org/freedesktop/compiz/core/screen0/{0}size".format(axis_to_orientation(axis)),
          "org.freedesktop.compiz.get",
          ]
    return int(check_output(c).split()[-1])
 
def set_num_workspaces(axis, n):
    c = [ "dbus-send",
            "--type=method_call",
            "--dest=org.freedesktop.compiz",
            "/org/freedesktop/compiz/core/screen0/{0}size".format(axis_to_orientation(axis)),
            "org.freedesktop.compiz.set",
            "int32:{0}".format(n),
            ]
    check_call(c)
 
if __name__ == "__main__":
    action = sys.argv[1] # one of 'set', 'add', 'del'
    axis = sys.argv[2] # one of 'x', 'y'
    n = None
 
    if action == "set":
        n = sys.argv[3]
    elif action == "add":
        n = get_num_workspaces(axis) + 1
    elif action == "del":
        n = get_num_workspaces(axis) - 1
 
    set_num_workspaces(axis, n)
 
# vim: et sw=4 ts=4:


