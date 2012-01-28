#!/usr/bin/env bash

# All of this is better to get from 'facter' (part of puppet)

# real hostname
echo -e "\nReal hostname: "
hostname=`hostname`
ip=`host $hostname |cut -f 4 -d ' '`
realhost=`host $ip | cut -f 5 -d ' '`
echo -e "$realhost"

# OS version
echo -e "\nOperating system: "
os=`lsb_release -a | grep -i Description` 
echo -e "$os"

# Number x Mhz of CPUs
echo -e "\nCPUs: "
cpus=`cat /proc/cpuinfo | egrep 'model name|cpu MHz'`
echo -e "\n$cpus"

# 64bit if 'lm' (long-mode) flag is present:
if cat /proc/cpuinfo | grep -q lm; then
    echo "  64bit CPU architecture"
else
    echo "  32bit CPU architecture"
fi

# Memory chip information
if [ -r /dev/mem ]; then 
    echo -e "\nMemory chips: "
    chips=`dmidecode|perl -n -e '$on=1 if /Memory Device$/; $on=0 if /^$/;print if $on'`
    echo -e "\n$chips"
fi

# Memory total/free
echo -e "\nMemory: "
mem=`free -m | grep '^Mem' | field 2`
echo -e "$mem MB"

echo -e "Swap space: "
swap=`free -m | grep '^Swap' | field 2`
echo -e "$swap MB"


# Disk partitions/usag
echo -e "\nDisk usage: "
df=`df -h`
echo -e "\n$df"

# Video card name and memory
echo -e "\nVideo:"
video=`lspci -v | grep 'VGA compatible controller'`
echo -e "\n$video"

