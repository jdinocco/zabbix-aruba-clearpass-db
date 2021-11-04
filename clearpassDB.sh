#!/bin/bash

PGPASS=$1
PGTARGET=$2
PGHOST=$3
INTERVAL=$4

export PGPASSWORD="$PGPASS"
NOW=$(date '+%Y-%m-%d %H:%M:%S')
PAST=$(date '+%Y-%m-%d %H:%M:%S' --date="$INTERVAL minutes ago")

radFail=$(psql -qtA -h $PGTARGET -d tipsLogDb -U appexternal -c "select count(id) from tips_radius_session_log where error_code != '0' and "timestamp" >= '$PAST' and "timestamp" <= '$NOW';")
radSuc=$(psql -qtA -h $PGTARGET -d tipsLogDb -U appexternal -c "select count(id) from tips_radius_session_log where error_code = '0' and "timestamp" >= '$PAST' and "timestamp" <= '$NOW';")
tacFail=$(psql -qtA -h $PGTARGET -d tipsLogDb -U appexternal -c "select count(user_session_id) from tips_tacacs_session_log where request_type = 'TACACS_AUTHENTICATION' and error_code != '0' and "timestamp" >= '$PAST' and "timestamp" <= '$NOW';")
tacSuc=$(psql -qtA -h $PGTARGET -d tipsLogDb -U appexternal -c "select count(user_session_id) from tips_tacacs_session_log where request_type = 'TACACS_AUTHENTICATION' and error_code = '0' and "timestamp" >= '$PAST' and "timestamp" <= '$NOW';")
radTotal=$(($radFail+$radSuc))
tacTotal=$(($tacFail+$tacSuc))
totalSuc=$(($radSuc+$tacSuc))
totalFail=$(($radFail+$tacFail))
totalAuth=$(($totalSuc+$totalFail))
radFailPercent=$(awk "BEGIN { pc=100*${radFail}/${radTotal}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
radSucPercent=$(awk "BEGIN { pc=100*${radSuc}/${radTotal}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
tacFailPercent=$(awk "BEGIN { pc=100*${tacFail}/${tacTotal}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
tacSucPercent=$(awk "BEGIN { pc=100*${tacSuc}/${tacTotal}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
totalFailPercent=$(awk "BEGIN { pc=100*${totalFail}/${totalAuth}; i=int(pc); print (pc-i<0.5)?i:i+1 }")
totalSucPercent=$(awk "BEGIN { pc=100*${totalSuc}/${totalAuth}; i=int(pc); print (pc-i<0.5)?i:i+1 }")

zabbix_sender -z 127.0.0.1 -s $PGHOST -k radFail -o $(echo $radFail)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k radSuc -o $(echo $radSuc)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k tacFail -o $(echo $tacFail)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k tacSuc -o $(echo $tacSuc)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k radTotal -o $(echo $radTotal)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k tacTotal -o $(echo $tacTotal)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k totalSuc -o $(echo $totalSuc)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k totalFail -o $(echo $totalFail)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k totalAuth -o $(echo $totalAuth)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k radFailPercent -o $(echo $radFailPercent)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k radSucPercent -o $(echo $radSucPercent)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k tacFailPercent -o $(echo $tacFailPercent)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k tacSucPercent -o $(echo $tacSucPercent)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k totalFailPercent -o $(echo $totalFailPercent)
zabbix_sender -z 127.0.0.1 -s $PGHOST -k totalSucPercent -o $(echo $totalSucPercent)