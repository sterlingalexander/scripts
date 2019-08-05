#!/bin/bash
# Kdump checking script by Steve Barcomb (sbarcomb@redhat.com)
#
# - 08-03-2019 Fixed issue where df filesystems were output on multiple lines.  Count from NF not $1
# - 07-26-2019 Added remote target detection, results were unpredictable.  Fixed HPSA firmware reporting, hopefully works this time.  Moved vmcore-dmesg detection. Changed root filesystem detection so that it looks for just / instead of lvm with a root name in it.
# - 07-24-2019 Improved device mapper detection, changed blacklist reporting for no 3rd party modules present, no more errors for no crashkernel reservation
# - 07-23-2019 Made blacklist checking much more robust.  Added total memory and dumptarget size for local volumes. Fixed double crash reservation arithmetic, grabs CCISS and HPSA firmware versions
# - 04-12-2018 Added a check to for a missing crashkernel reservation so it does not report a syntax error
# - 04-11-2018 This version will now check for systemd vs sysvinit scripts
# It also will calculate the size of the crash kernel reservation if the sosreport captures /proc/iomem



echo Kdump version:
echo --------------
echo $ grep kexec installed-rpms 
grep kexec installed-rpms
echo
echo

echo Checking for saved vmcore-dmesg.txt:
echo ------------------------------------
vmcore=$(find . -name vmcore.dmesg.txt 2>/dev/null)
if [ -z "$vmcore" ]
then
        echo No vmcore data found.
	echo
	echo
else
        echo $vmcore
	echo
	echo
fi


echo Checking to see if the kdump service is running:
echo ------------------------------------------------

if [ ! -f sos_commands/systemd/systemctl_list-units ] 
then
	grep kdump chkconfig

else
	grep kdump ./sos_commands/systemd/systemctl_list-units | awk '{print $2,$3,$4}'
fi

echo
echo
echo Printing /etc/kdump.conf:
echo -------------------------
echo '$ grep -v ^# etc/kdump.conf | grep -v ^$'
grep -v ^# etc/kdump.conf | grep -v ^$
echo
echo

if [ ! -f proc/iomem ] 
then 
	echo Crashkernel reservation from /proc/cmdline:
	echo -------------------------------------------
	cat proc/cmdline
	echo
	echo
else
	reservation_count=$(grep -i crash proc/iomem | wc -l)
        if [ $reservation_count -eq 0 ]
        then
		echo Crashkernel reservation:
		echo ------------------------
                echo No crashkernel reservation found
		echo
		echo
	elif [ $reservation_count -eq 1 ]
	then
		BIGGER=$(grep -i crash proc/iomem | awk -F '-' '{print $2}' | sed 's/\ \:\ Crash\ kernel//g'| tr /a-z/ /A-Z/)
		SMALLER=$(grep -i crash proc/iomem | awk -F '-' '{print $1}' | sed 's/\ //g'| tr /a-z/ /A-Z/)
		echo Crashkernel reservation:
		echo ------------------------	
		SIZE=$(echo "ibase=16;$BIGGER - $SMALLER"|bc)
		VALUE=$(echo $SIZE/1024/1024|bc)
		echo The crashkernel value from /proc/iomem is $VALUE MiB
		echo
		echo
	else
		BIGGER1=$(grep -i crash proc/iomem | head -n1 | awk -F '-' '{print $2}' | sed 's/\ \:\ Crash\ kernel//g'| tr /a-z/ /A-Z/)
		SMALLER1=$(grep -i crash proc/iomem | head -n1 | awk -F '-' '{print $1}' | sed 's/\ //g'| tr /a-z/ /A-Z/)
		BIGGER2=$(grep -i crash proc/iomem | tail -n1 | awk -F '-' '{print $2}' | sed 's/\ \:\ Crash\ kernel//g'| tr /a-z/ /A-Z/)
		SMALLER2=$(grep -i crash proc/iomem | tail -n1 | awk -F '-' '{print $1}' | sed 's/\ //g'| tr /a-z/ /A-Z/)
		SIZE1=$(echo "ibase=16;$BIGGER1 - $SMALLER1"|bc)
		SIZE2=$(echo "ibase=16;$BIGGER2 - $SMALLER2"|bc)
		VALUE1=$(echo $SIZE1/1024/1024|bc)
		VALUE2=$(echo $SIZE2/1024/1024|bc)
		TVALUE=$[$VALUE1+$VALUE2]
		echo Crashkernel reservation:
		echo ------------------------
		echo The crashkernel has two reservations and the value from /proc/iomem is $TVALUE MiB
		echo
		echo
	fi
fi

memtotalkb=$(grep MemTotal proc/meminfo | awk '{print $2}')
memtotalgb=$(echo "scale=2;$memtotalkb/1024/1024" | bc)
echo Total memory on the system:
echo ---------------------------
echo $memtotalgb GiB
echo
echo

nettarget=$(grep -e nfs -e net -e ssh etc/kdump.conf | grep -v ^#) 
uuidtarget=$(grep UUID etc/kdump.conf | grep -v ^# |awk '{print $2}' | awk -F "=" '{print $2}')
devicetarget=$(grep -e ext4 -e xfs etc/kdump.conf | grep '/' | grep -v ^# | awk '{print $2}' | awk -F"/" '{print $NF}')
pathtarget=$(grep path etc/kdump.conf | grep -v ^# | awk '{print $2}')

if [[ $nettarget ]]
then 
	echo Dump target size:
	echo -----------------
	echo Remote dump target, please check this manually 

elif [[ $uuidtarget ]]
then uuidfs=$(grep $uuidtarget ./sos_commands/block/blkid* | awk '{print $1}'| tr -d ':') 	
	uuidfszkb=$(grep $uuidfs df | awk '{print $4}')
	uuidfszgb=$(echo "scale=2;$uuidfszkb"/1024/1024 | bc)
	echo Dump target size:
	echo -----------------
	echo $uuidfszgb GiB
	if [ $memtotalkb -gt $uuidfszkb ]
	then
		echo
		echo
		echo *WARNING* dump target may not be sufficiently sized
	else
		:
	fi
elif [[ $devicetarget ]]
then devicefszkb=$(grep $devicetarget df | awk '{print $4}')
	devicefszgb=$(echo "scale=2;$devicefszkb"/1024/1024 | bc)
        echo Dump target size:
        echo -----------------
        echo $devicefszgb GiB	
        if [ $memtotalkb -gt $devicefszkb ]
        then
                echo
                echo
                echo *WARNING* dump target may not be sufficiently sized
        else
                :
        fi
elif [[ $pathtarget ]]
then paths=$(echo "$pathtarget" | sed 's/\// /g' | awk '{for(i=NF;i>=1;i--) printf "%s ", $i;print ""}')
	j=0
	for i in $paths
	do
		number=$(grep "$i"$ df | awk '{print $(NF)}' | grep -v ^'/sys' | grep -v ^'/var/lib' | wc -l)
		if [ $number -ne 0 ]
		then	
			if [ $number -ne 0 ] && [ $j -ne 0 ]
			then
				dir=$i
				break
			fi
		else 
			dir="root"
			let "j=j+1"
		fi
	done
	if [ $dir = root ]
	then
        	pathszkb=$(cat df | grep -v rootfs | awk '{print $6, $4}' | grep ^/[[:space:]] | awk '{print $2}')
        	pathszgb=$(echo "scale=2;$pathszkb"/1024/1024 | bc)
        	echo Dump target size:
        	echo -----------------
	        echo $pathszgb GiB
		if [ $memtotalkb -gt $pathszkb ]
		then
			echo
			echo
			echo *WARNING* dump target may not be sufficiently sized
		else
			:
		fi
	else
		pathszkb=$(grep "$dir"$ df| awk '{print $(NF-2)}')
		pathszgb=$(echo "scale=2;$pathszkb"/1024/1024 | bc)
		echo Dump target size:
		echo -----------------
		echo $pathszgb GiB
	                if [ $memtotalkb -gt $pathszkb ]
	                then
	                        echo
  				echo
				echo *WARNING* dump target may not be sufficiently sized
			else
				:
			fi
fi
else
	echo Either the dump target is not local or not found in the sosreport	
fi
echo
echo

echo Panic tunables:
echo ---------------
echo $ grep panic ./sos_commands/kernel/sysctl_-a
grep panic ./sos_commands/kernel/sysctl_-a
echo
echo
echo Checking for sysrq keybinding:
echo ------------------------------
echo $ grep sysrq ./sos_commands/kernel/sysctl_-a
grep sysrq ./sos_commands/kernel/sysctl_-a
echo
echo
echo Generating a blacklist for third party modules:
echo -----------------------------------------------
modulesexists=$(ls proc | grep modules | wc -l)
if [ $modulesexists -eq 0 ]
then 
	echo "/proc/modules not found in sosreport"
else
	blacklist=$(grep $')' proc/modules | awk '{print $1}'| tr '\n' ' ')
	if [ -z "$blacklist" ]
	then
		echo "No third party modules found in /proc/modules"
	else 
	echo $blacklist
	fi
fi
echo
echo

if grep --quiet cciss lsmod;
then
	echo 'CCISS firmware version:'
	echo '---------------------'
	cciss=$(grep -i version proc/driver/cciss/cciss0)
	echo CCIS Version $cciss
	
else
	:
fi

if grep --quiet hpsa lsmod;
then
	echo 'HPSA firmware version:'
	echo '----------------------'
	grep scsi ./sos_commands/kernel/dmesg | grep RAID | grep HP | sed -e 's/\[[^][]*\]//g' | grep -v hpsa | sed -e s/scsi//g | sed -e s/RAID//g | awk '{print $2,$3,"Firmware Version",$4}'
else
	:
fi
echo
echo



