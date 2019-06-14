#!/bin/bash
hostname="`hostname`.us.fit"
epoch=$(date +%s)
file=/tmp/passive_checks
centreon="/opt/monitoring/centreon-plugins/centreon_plugins.pl --plugin os::linux::local::plugin"

# Modes Available:
#    cmd-return
#    connections
#    cpu
#    cpu-detailed
#    diskio
#    files-date
#    files-size
#    inodes
#    list-interfaces
#    list-partitions
#    list-storages
#    load
#    memory
#    packet-errors
#    paging
#    process
#    storage
#    swap
#    traffic
#    uptime

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}


## Disk ##
for disk in `df -P -k -l -x iso9660 -t ext4 -t ext2 -t reiserfs -t xfs | awk '{print $6}' | grep -v Mounted`; do
  #message=`/opt/monitoring/plugins/fit-plugins/check_disk_unix -w 90 -c 95 -d $disk`
  message=`$centreon  --mode storage --warning 90 --critical 95 --range-perfdata 1 --name $disk`
  status=`echo $?`
  epoch=$(date +%s)
  echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;disk $disk;$status;${message}" >> $file
done



#check_load=`/usr/lib/nagios/plugins/check_load - r -w 10,15,20 -c 15,20,25`
check_load=`$centreon --mode load --warning  10,15,20 --critical 15,20,25`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;load;$?;${check_load}" >> $file

#check_procs=`/usr/lib/nagios/plugins/check_procs -w 2000 -c 2000`
check_procs=`$centreon --mode process --warning 2000 --critical 2000 --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;procs;$?;${check_procs}" >> $file

#memory_physical=`/usr/lib/nagios/plugins/fit-plugins/check_mem.pl -u -w 98 -c 99`
memory_physical=`$centreon --mode memory --warning 100 --critical 101 --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;memory_physical;$?;${memory_physical}" >> $file

#memory_swap=`/usr/lib/nagios/plugins/fit-plugins/check_swap.sh -w 70 -c 90`
memory_swap=`$centreon --mode paging --warning 70 --critical 90 --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;memory_swap;$?;${memory_swap}" >> $file

diskio=`$centreon --mode diskio --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;diskio;$?;${diskio}" >> $file

cpu=`$centreon --mode cpu --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;cpu;$?;${cpu}" >> $file

traffic=`$centreon --mode traffic --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;traffic;$?;${traffic}" >> $file

connections=`$centreon --mode connections --range-perfdata 1`
echo "[$epoch] PROCESS_SERVICE_CHECK_RESULT;$hostname;connections;$?;${connections}" >> $file

netcat -z 153.95.210.47 5667

if [ $? != 0 ]; then
  echo "Critical - last command exection $(date) failed!"
  exit 1
fi

curl -s -d username="default" -d password="changeme" --data-urlencode input@$file http://153.95.210.47:5667/queue
echo "OK - last command execution $(date)"
rm -f $file

