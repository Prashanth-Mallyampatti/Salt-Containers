#!/bin/bash
#
# Checks SWAP usage as a % of the total swap
#
# Date: 05/12/13
# Author: Nick Barrett - EDITD
# License: MIT
#
# Usage: check-swap-percentage.sh -w warn_percent -c critical_percent
# Uses free (Linux-only) & bc
##
##
## REVISIONS
# Date: 2015/12/12
# Editor: itpowe
# Notes:
#	added check for AIX/Linux determination of swap space
#	modified output to match current plugin output
#

# #RED
# input options
while getopts ':w:c:' OPT; do
  case $OPT in
    w)  WARN=$OPTARG;;
    c)  CRIT=$OPTARG;;
  esac
done

WARN=${WARN:=100}
CRIT=${CRIT:=100}

# OS TYPE
DISTRO=`uname`

if [[ $DISTRO == *"Linux"* ]];
  then 
	# get swap details LINUX
	TOTAL=`free -m | grep 'Swap:' | awk '{ print $2 }'`
	USED=`free -m | grep 'Swap:' | awk '{ print $3 }'`
  else
        # get swap details AIX
        TOTAL=`lsps -s | grep -v -i 'space' | awk -F'[MB]' '{printf "%d", $1}'`
        USED=`lsps -s | grep -v -i 'space' | awk '{printf "%d", $2}'`
        USED=`echo "scale=3;$TOTAL*$USED/100" | bc -l | awk '{printf "%.0f", $0}'`
fi  

if [[ $TOTAL -eq 0 ]] ; then
  echo "There is no SWAP on this machine"
  exit 0
else
  PERCENT=`echo "scale=3;$USED/$TOTAL*100" | bc -l | awk '{printf "%.0f", $0}'`
  WARNVALUE=`echo "scale=3;$TOTAL*($WARN/100)" | bc -l | awk '{printf "%.0f", $0}'`
  CRITVALUE=`echo "scale=3;$TOTAL*($CRIT/100)" | bc -l | awk '{printf "%.0f", $0}'`

  OUTPUT="$PERCENT% used ($USED MB out of $TOTAL MB) |swap=$USED""MB;$WARNVALUE;$CRITVALUE;0;$TOTAL"

  if [ $PERCENT -ge $CRIT ] ; then
    echo "SWAP CRITICAL - $OUTPUT"
    exit 2
  elif [ $PERCENT -ge $WARN ] ; then
    echo "SWAP WARNING - $OUTPUT"
    exit 1
  else
    echo "SWAP OK - $OUTPUT"
    exit 0
  fi
fi
