#!/bin/bash
# by Paul Colby (http://colby.id.au), no rights reserved ;)

PREV_TOTAL=0
PREV_IDLE=0

#for ((i=0;i<2;i=$i+1)); do 
while true; do 
  CPU=(`cat /proc/stat | grep '^cpu '`) # Get the total CPU statistics.
  unset CPU[0]                          # Discard the "cpu" prefix.
  USER=${CPU[1]}
  NICE=${CPU[2]}
  SYSTEM=${CPU[3]}
  IDLE=${CPU[4]}                        
#  IOWAIT=${CPU[5]}                        
  IOWAIT=0
#  IRQ=${CPU[6]}                        
  IRQ=0
#  SOFTIRQ=${CPU[7]}                        
  SOFTIRQ=0

  # Calculate the total CPU time.
  TOTAL=$(($USER+$NICE+$SYSTEM+$IDLE+$IOWAIT+$IRQ+$SOFTIRQ))

  # Calculate the CPU usage since we last checked.
  let "DIFF_IDLE=$IDLE-$PREV_IDLE"
  let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
  let "DIFF_USAGE=(1000*($DIFF_TOTAL-$DIFF_IDLE)/$DIFF_TOTAL+5)/10"
  echo -en "\rCPU: $DIFF_USAGE%  \b\b"

  # Remember the total and idle CPU times for the next check.
  PREV_TOTAL="$TOTAL"
  PREV_IDLE="$IDLE"

  # Wait before checking again.
  sleep 2
done

