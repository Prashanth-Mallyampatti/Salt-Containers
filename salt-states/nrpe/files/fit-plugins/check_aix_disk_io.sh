#!/bin/ksh
#
# check_disk_io
#
# This plugin checks IO for needed disks
# Author: Bratislav STOJKOVIC
# E-mail:bratislav.stojkovic@gmail.com
# Version: 0.1
# Last Modified: October 2013

PROGNAME=`basename $0`
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
REVISION=`echo 'Revision: 0.1'`
. $PROGPATH/utils.sh
STATE1=
STATE2=

print_usage() {
        echo "Usage: $PROGNAME -d <comma_separated_disk_list> -w <warning_threshold> -c <critical_threshold>"
}

print_revision() {
        echo $PROGNAME $REVISION
        echo ""
        echo "This plugin checks IO for needed disks"
        echo ""
        exit 0
}

if [ $# -eq 1 ] && ([ "$1" == "-h" ] || [ "$1" == "--help" ]); then
        print_usage
        exit $STATE_UNKNOWN
elif [ $# -lt 6 ]; then
        print_usage
        exit $STATE_UNKNOWN
fi

while test -n "$1"; do
case "$1" in
        --help)
                print_usage
                exit 0
                ;;
        -h)
                print_usage
                exit 0
                ;;
        -V)
                print_revision $PROGNAME $REVISION
                exit 0
                ;;
        -d)
            TEMP1=$2
            HDISK=`echo $2|sed  's/,/ /g'`
            shift
            ;;
        -w)
            WARNING=$2
            shift
            ;;
        -c)
            CRITICAL=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
esac
shift
done

IOSTAT_PERF=`/usr/bin/iostat -d $HDISK 1 1| grep hdisk| awk '{print $1"_Busy="$2";"'$WARNING'";"'$CRITICAL'" "$1"_tps="$4" "$1"_KbRd="$5" "$1"_KbWt="$6}'`

disk_output()
{
for I in `echo "$1"`
do
        IOSTAT_DISK=`echo $I | grep Busy|awk -F"_Busy=" '{print $1}'`
        IOSTAT_BUSY=`echo $I | grep Busy|awk -F"_Busy=" '{print $2}'| awk -F";" '{print $1}'`
        if [[ $IOSTAT_BUSY -gt $2 ]]; then
                echo "$IOSTAT_DISK = $IOSTAT_BUSY% busy \c"
        fi
done
}

for IOSTAT in `echo "$IOSTAT_PERF"`
do
IOSTAT_BUSY=`echo $IOSTAT | grep Busy|awk -F"_Busy=" '{print $2}'| awk -F";" '{print $1}'`
        if [[ $IOSTAT_BUSY -gt $CRITICAL ]]; then
                STATE2=$STATE_CRITICAL

        elif [[ $IOSTAT_BUSY -gt $WARNING ]]; then
                STATE1=$STATE_WARNING
        fi
done

if [[ -n $STATE2 ]]; then
        DISK_CRITICAL=$(disk_output "$IOSTAT_PERF" "$CRITICAL")
        echo "CRITICAL:"$DISK_CRITICAL"|"$IOSTAT_PERF
        exit $STATE_CRITICAL
elif [[ -n $STATE1 ]]; then
        DISK_WARNING=$(disk_output "$IOSTAT_PERF" "$WARNING")
        echo "WARNING:"$DISK_WARNING"|"$IOSTAT_PERF
        exit $STATE_WARNING
else
        echo "OK: All disks are in normal state.|"$IOSTAT_PERF
        exit $STATE_OK
fi
