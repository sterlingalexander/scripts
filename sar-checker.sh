#!/bin/bash
# 07/26/2019 - Initial version


jan=01
feb=02
mar=03
apr=04
may=05
jun=06
jul=07
aug=08
sep=09
oct=10
nov=11
dec=12

sosmonth=$(cat date |  awk '{print $2}')
sosdate=$(cat date | awk '{print $3}')
soshour=$(cat date |  awk '{print $4}' | awk -F ':' '{print $1}')
sosminute=$(cat date | awk '{print $4}' | awk -F ':' '{print $2}')

sosdateraw=$(echo $sosdate | wc -w)
if [ $sosdateraw -eq 1 ]
then
	sosdate2d=$(echo $sosdate | sed 's/^/0/g')
else
	sosdate2d=$sosdateraw
fi

sarfilename=$(echo $sosdate2d | sed 's/^/sar/g')
sarfileloc=$(find . -name $sarfilename)
sarfilemonth=$(head -n1 $sarfileloc | awk '{print $4}' | awk -F '/' '{print $1}')
sarfiledate=$(head -n1 $sarfileloc | awk '{print $4}' | awk -F '/' '{print $2}')
sarfileyear=$(head -n1 $sarfileloc | awk '{print $4}' | awk -F '/' '{print $3}')
echo $sarfilemonth
echo $sarfiledate
echo $sarfileyear

