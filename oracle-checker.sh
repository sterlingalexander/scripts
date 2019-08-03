echo Looking to see what io scheduler we are using and is transparent hugepages are disabled
echo '$ grep -e elevator -e transparent proc/cmdline'
grep -e elevator -e transparent proc/cmdline
echo
echo
echo '$ grep -i huge proc/meminfo' 
grep -i huge proc/meminfo
echo
echo
echo '$ cat proc/sys/vm/swappiness' 
echo "$( cat proc/sys/vm/swappiness) <==== we recommend 10"
echo
echo '$ cat proc/sys/vm/dirty_ratio'
echo "$( cat proc/sys/vm/dirty_ratio) <==== we recommend 15"
echo
echo '$ cat proc/sys/vm/dirty_background_ratio'
echo "$( cat proc/sys/vm/dirty_background_ratio) <==== we recommend 3"
echo
echo '$cat proc/sys/vm/dirty_writeback_centisecs'
echo "$( cat proc/sys/vm/dirty_writeback_centisecs) <==== we recommend 100"
echo
echo '$ cat proc/sys/vm/dirty_expire_centisecs'
echo "$( cat proc/sys/vm/dirty_expire_centisecs) <==== we recommend 500"
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
