#!/bin/bash

dir=`dirname "$0"`

locks=${locks:-"$dir/locks"}
file=${file:-"$dir/data/$(date +%Y-%m).csv"}
compareFile=${file:-"$dir/data/$(date -d '24 hours ago' +%Y-%m).csv"}
compareDate=`date '+%F %H:%M' --date='24 hours ago'`
alarm_log=${alarm_log:-"$dir/larm.log"}
email=${email:-felanmalan@skrytetorp.se}

nowLevel=`tail -n 5 "$file" | awk '{print $4}' | sort -n | head -n 3 | tail -n 1`
thenLevel=`grep "$compareDate" -C 2 "$compareFile" | awk '{print $4}' | sort -n | head -n 3 | tail -n 1`
diff=`expr $nowLevel - $thenLevel`

if [ $diff -lt -50 ]
then
    msg="Läckagelarm: $diff l på 24 timmar! Från $thenLevel till $nowLevel liter."
    echo "`date '+%F %H:%M'` $msg" >> "$alarm_log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/leak.lock")` -gt 3600 ]
    then
        { echo -e "`date`    $msg\n" && tail -n 5 "$file"; } | mail -s "[Expansionskärl] $msg" $email
        touch "$locks/leak.lock"
    fi
fi
if [ $nowLevel -lt 40 ]
then
    msg="Kritisk nivå larm: $nowLevel l kvar!"
    echo "`date '+%F %H:%M'` $msg" >> "$alarm_log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/level1.lock")` -gt  3600 ]
    then
        { echo -e "`date`    $msg\n" && tail -n 5 "$file"; } | mail -s "[Expansionskärl] $msg" $email
        touch "$locks/level1.lock"
    fi
elif [ $nowLevel -lt 60 ]
then
    msg="Låg nivå larm: $nowLevel l kvar!"
    echo "`date '+%F %H:%M'` $msg" >> "$alarm_log"
    if [ `expr $(date +%s) - $(stat -c %Y "$locks/level2.lock")` -gt  86400 ]
    then
        { echo -e "`date`    $msg\n" && tail -n 5 "$file"; } | mail -s "[Expansionskärl] $msg" $email
        touch "$locks/level2.lock"
    fi
fi
