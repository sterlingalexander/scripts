#!/bin/bash
# Basic RCA script
# Steve Barcomb (sbarcomb@redhat.com
# 2018-04-26
#

mockbuild=$(grep -i mockbuild var/log/messages | sort -u)

echo Hostname:
echo ---------
echo $ cat hostname
cat hostname
echo 
echo
echo Red Hat Enterprise Linux Version:
echo ---------------------------------
echo $ cat etc/redhat-release
cat etc/redhat-release
echo
echo
echo Date that the sosreport was collected:
echo --------------------------------------
echo $ cat date
cat date
echo
echo
echo Uptime output:
echo --------------
echo $ cat uptime
cat uptime
echo
echo
echo Hardware type:
echo --------------
echo $ grep -A 2 "System Information" dmidecode
grep -A 2 "System Information" dmidecode
echo
echo
echo Checking for kernel build server information:
echo ---------------------------------------------

if [ -z "$mockbuild" ]
then
        echo No mockbuild found in messages, not continuing
else
	grep -i mockbuild var/log/messages | sort -u
fi

echo
echo
echo Grabbing /var/log/messages data prior to the reboot:
echo ----------------------------------------------------

if [ -z "$mockbuild" ]
then
        echo No mockbuild found in messages, not continuing
else
	echo $ grep -B 20 mockbuild var/log/messages
	grep -B 20 mockbuild var/log/messages
fi
echo
echo

if [ -z "$mockbuild" ]
then
	echo Grabbing performance data in $sarfile:
	echo ---------------------------------------------------------------

	echo No mockbuild found in messages, not continuing
else
	if [ "$sarmonth" == "$monthnum" ]
	then

testdate=$(grep -B 20 mockbuild var/log/messages | awk '{print $2}' | tail -n1)
datelen="${#testdate}"

month=$(grep -B 20 mockbuild var/log/messages | awk '{print $1}' | tail -n1)

if [ "$month" = Jan ]
then
        monthnum="01"
fi

if [ "$month" = Feb ]
then
        monthnum="02"
fi

if [ "$month" = Mar ]
then
        monthnum="03"
fi

if [ "$month" = Apr ]
then
        monthnum="04"
fi

if [ "$month" = May ]
then
        monthnum="05"
fi

if [ "$month" = Jun ]
then
        monthnum="06"
fi

if [ "$month" = Jul ]
then
        monthnum="07"
fi

if [ "$month" = Aug ]
then
        monthnum="08"
fi

if [ "$month" = Sep ]
then
        monthnum="09"
fi

if [ "$month" = Oct ]
then
        monthnum="10"
fi

if [ "$month" = Nov ]
then
        monthnum="11"
fi

if [ "$month" = Dec ]
then
        monthnum="12"
fi


if [ $datelen = 1 ]
then
        date="0$testdate"
else
        date=$testdate
fi

sardate="sar"
sardate+=$date
sarfile=$(find . | grep $sardate)

sarmonthnum=$(head -n1 $sarfile | awk '{print $4}' | awk -F "-" '{print $2}')


		echo Grabbing performance data in $sarfile:
		echo ---------------------------------------------------------------
		head -n1 $sarfile
	else
		echo The sar file found is not the correct month, please validate this manually
	fi
fi







