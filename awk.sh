#!/bin/sh
# this is a shell script that acts like a filter,
# but in only prints out one column.
# the value of the column is the argument 
# to the script
#
# uncomment the next line to see how this works
set -x
#
# example:
#      printcol 1
#      printcol 3
# the value of the argument is 
# Here comes the tricky part -
awk '{print $''}'
# I told you!
