#!/bin/bash
# - 08-03-2019 Modernizing some stuff
# Initial update Steve Barcomb (sbarcomb@redhat.com)


hugepagesz=$(grep Hugepagesize proc/meminfo | awk '{print $2}')
hugepagenr=$(grep HugePages_Total proc/meminfo | awk '{print $2}')
hugepagegb=$(echo "scale=2;$hugepagesz*$hugepagenr/1024/1024" | bc)

echo Looking to see what io scheduler we are using and is transparent hugepages are disabled
echo '$ grep -e elevator -e transparent proc/cmdline'
grep -e elevator -e transparent proc/cmdline
echo
echo
echo Number of allocated hugepages:
echo ------------------------------
echo $hugepagenr
echo
echo
echo Total hugepage allocation in GiB:
echo ---------------------------------
echo $hugepagegb
echo
echo
echo Swappiness value of 1-10 is recommended:
echo ----------------------------------------
echo "$(grep swappiness ./sos_commands/kernel/sysctl_-a)"
echo
echo
echo Dirty ratio value of 15 for large memory systems is recommended:
echo ----------------------------------------------------------------
echo "$(grep dirty_ratio ./sos_commands/kernel/sysctl_-a)"
echo
echo
echo Dirty backgroud ratio value should be 3:
echo ----------------------------------------
echo "$(grep dirty_background_ratio ./sos_commands/kernel/sysctl_-a)"
echo
echo
echo Dirty writeback centisecs value should be 100:
echo ----------------------------------------------
echo "$(grep dirty_writeback_centisecs ./sos_commands/kernel/sysctl_-a)"
echo
echo
echo Dirty expire centisecs value should be 500:
echo -------------------------------------------
echo "$(grep dirty_expire_centisecs ./sos_commands/kernel/sysctl_-a)"
echo
echo
mem=$(cat free|grep Mem|awk '{print $2}')
totmem=$(echo "$mem*1024"|bc)
huge=$(grep Hugepagesize proc/meminfo|awk '{print $2}')
max=$(echo "$totmem*75/100"|bc)
all=$(echo "$max/$huge"|bc)
echo Checking for the shmmax value
echo "$(grep kernel.shmmax ./sos_commands/kernel/sysctl_-a) <==== should be $max based on the sosreport"
echo
echo Checking for the shmmall value
echo "$(grep kernel.shmall ./sos_commands/kernel/sysctl_-a) <==== should be $all based on the sosreport"
echo
echo Checking the shmmni value
echo "$(grep kernel.shmmni ./sos_commands/kernel/sysctl_-a) <==== should be 4096"
echo
echo Checking semaphore minimums
echo "$(grep kernel.sem ./sos_commands/kernel/sysctl_-a) <==== should be 250 32000 100 128"
echo
echo Checking open file descriptors for the Oracle user
echo "$(grep oracle etc/security/limits.conf | grep hard | grep nofile) <==== should be at least 10000"
echo
echo
echo Checking to see if tuned and ktune are running
echo '$ grep tune chkconfig'
grep tune chkconfig
