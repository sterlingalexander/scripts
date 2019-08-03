#/bin/bash

dirs=$( find /Users/sbarcomb/cases -atime 14 -type d | awk -F '/' '{print $5}' | sort -u )
for i in $dirs;do sudo rm -rf /Users/sbarcomb/cases"$i";done
