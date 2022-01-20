#!/bin/sh

[ -z "$1" ] && { echo "error no host given in arguments"; exit 1; }
host="$1"
opts="-e 'ssh -p2002'"

script="$(basename "$0")"
test="rsync ${opts} root@${host}:/vm/cloud/.* /vm/cloud/.*"
cmd="rsync ${opts} root@${host}:/vm/cloud/ /vm/cloud/ -av --delete"
file=/var/log/server/${script}.log
file_out=/var/log/server/${script}-out.log

if ps u -C rsync|grep -q "${test}"; then
	echo "$(date +%D-%H%M%S) - $(df -h |awk '/^root\/vm\/cloud/ {print $3}') ok" >> ${file}
else
	echo "$(date +%D-%H%M%S) - $(df -h |awk '/^root\/vm\/cloud/ {print $3}') launch - ${cmd}" >> ${file}
	eval ${cmd} >> ${file_out} &
fi

