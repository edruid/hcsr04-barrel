#!/usr/bin/env python3

import os
import datetime
from pathlib import Path
import subprocess
import statistics

dir = os.path.dirname(os.path.realpath(__file__))
locks = os.environ.get('locks', dir + '/locks')
file  = os.environ.get(
    'file',
    dir + '/data/' + datetime.date.today().strftime('%Y-%m') + '.csv'
)
compareFile  = os.environ.get(
    'file',
    dir + '/data/' + (datetime.date.today() - datetime.timedelta(days=1)).strftime('%Y-%m') + '.csv'
)
compareDate = (datetime.datetime.now() - datetime.timedelta(days=1)).strftime('%F %H:%M')
alarm_log = os.environ.get('alarm_log', dir + '/larm.log')
emails = os.environ.get('email', 'felanmalan@skrytetorp.se').split(',')

def runCmd(*cmd):
    out = ''
    with subprocess.Popen(cmd, stdout=subprocess.PIPE) as f:
        out += f.stdout.read().decode('utf-8')
    for line in out.split('\n'):
        if line:
            yield line

def mail(title, body, recep):
    with subprocess.Popen(
        ['mail', '-s', title, *recep],
        stdin=subprocess.PIPE
    ) as f:
        f.communicate(input=body.encode('utf-8'))
        

def meanLevel(lines):
    ultr = []
    laser = []
    for line in lines:
        _, _, u, _, l = line.split('\t')
        ultr.append(int(u))
        laser.append(int(l))
    laser = statistics.median(laser)
    if laser != -1:
        return laser
    return statistics.median(ultr)
        
def getLock(lock, freq):
    lo = Path(lock)
    if not lo.exists():
        lo.touch()
        return True
    if datetime.datetime.fromtimestamp(lo.stat().st_mtime) + freq < datetime.datetime.now():
        lo.touch()
        return True
    return False

def alarm(msg, freq, lock):
    t = datetime.datetime.now().strftime('%F %H:%M')
    with open(alarm_log, 'a') as f:
        f.write(t + '\t' + msg + '\n')
    if getLock(lock, freq):
        title = '[Expansionskärl] ' + msg
        body = f"{t}    {msg}\n\nmättid - mm (ultra) - l (ultra) - mm (laser) - l (laser)"
        for line in runCmd('tail', '-n', '5', file):
            body += line + '\n'
        mail(title, body, emails)


lvl = meanLevel(runCmd('tail', '-n', '5', file))
oldLvl = meanLevel(runCmd('grep', compareDate, '-C', '2', compareFile))
diff = lvl - oldLvl

if diff < -50:
    alarm(
        f"Läckagelarm: {diff} l på 24 timmar! Från {oldLvl} till {lvl} liter.",
        datetime.timedelta(hours=1),
        locks + '/leak.lock'
    )
if lvl < 40:
    alarm(
        f'Kritisk nivå larm: {lvl} l kvar!',
        datetime.timedelta(hours=1),
        locks + '/level1.lock'
    )
elif lvl < 60:
    alarm(
        f'Låg nivå larm: {lvl} l kvar!',
        datetime.timedelta(days=1),
        locks + '/level2.lock'
    )

