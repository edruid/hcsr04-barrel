#!/bin/bash

dir=`dirname "$0"`
locks="$dir/locks"
file="$dir/vattennivå.csv"
email=felanmalan@skrytetorp.se
email=eric.druid@gmail.com
compareDate=`date '+%F %H:%M' --date='10 hours ago'`
nowLevel=`tail -n 5 "$file" | awk '{print $4}' | sort -n | head -n 3 | tail -n 1`
thenLevel=`grep "$compareDate" -C 2 "$file" | awk '{print $4}' | sort -n | head -n 3 | tail -n 1`
diff=`expr $nowLevel - $thenLevel`

if [ $diff -lt -40 ]
then
    msg="Läckagelarm: $diff l på 10 timmar! Från $thenLevel till $nowLevel liter."
    echo "`date '+%F %H:%M'` $msg" >> "$dir/larm.log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/leak.lock") \> 3600` ]
    then
        echo "`date`\n$msg" | mail -s "[Expansionskärl] $msg" "$email"
	touch "$locks/leak.lock"
    fi
fi
if [ $nowLevel -lt 40 ]
then
    msg="Kritisk nivå larm: $nowLevel l kvar!"
    echo "`date '+%F %H:%M'` $msg" >> "$dir/larm.log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/level1.lock") \> 3600` ]
    then
        echo "`date`\n$msg" | mail -s "[Expansionskärl] $msg" "$email"
	touch "$locks/level1.lock"
    fi
elif [ $nowLevel -lt 50 ]
then
    msg="Låg nivå larm: $nowLevel l kvar!"
    echo "`date '+%F %H:%M'` $msg" >> "$dir/larm.log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/level2.lock") \> 3600 \* 24` ]
    then
        echo "`date`\n$msg" | mail -s "[Expansionskärl] $msg" "$email"
	touch "$locks/level2.lock"
    fi
fi